--!nocheck
--==============================================================================
-- Steal a Seed :: AutoWeatherSpec (2026-10-05; ON THE HOUR since 2026-10-16)
--
-- Automatic weather (WeatherService's scheduler; GameConfig.Weather.Auto), as
-- the owner set it on 2026-10-16: every 60 minutes, fixed; every server at the
-- same minute (on the hour); 3 minutes; Rain or a Thunderstorm 90/10; it may
-- fall during the Enchanted Mist. The owner's settings validate and broken ones
-- turn it off; the marks are on the hour; weather starts AT the mark, through
-- the console's own path, once per mark; the mode is the same on every server
-- for the same mark (a draw seeded by the mark); a mark that cannot start at
-- once (the console's weather running, nobody here, a server just up) starts
-- later in its window for what is left, ending with everybody else's, or is
-- missed; a held-up loop never catches up; the next mark is published for the
-- RAIN BIOME sign; a failed start uses its mark; Init, Start and Stop keep one
-- loop and no stale state. Edit mode, on the spec's own clock -- no real
-- minutes pass.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local WeatherService = require(Server.WeatherService)

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
local A = W.Auto
local ATTR = W.Attributes
local EVENTS = W.Events
local NEXT_AT = A.NextAtAttribute
local HOUR = 3600

local scratch = Instance.new("Folder")
scratch.Name = "ZZAutoWeatherSpec"
scratch.Parent = Workspace

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

--==============================================================================
-- THE SEAMS: a clock, a player list, a terrain that counts, a recording remote
-- and a nest that lays three. The mode draw is the real one (seeded by the
-- mark) unless a section says otherwise.
--==============================================================================
local now = 500000
local alice = standIn("Alice", 1, Vector3.new(0, 3, 0))
local players = { alice }
local builds, destroys, sent = 0, 0, {}
local buildOk = true
WeatherService.useClock(function()
	return now
end)
WeatherService.usePlayers(function()
	return players
end)
WeatherService.useTerrain({
	build = function(parent)
		builds += 1
		if not buildOk then
			return nil
		end
		local f = Instance.new("Folder")
		f.Name = "ZZFakeRainTerrain"
		f.Parent = scratch
		return f
	end,
	setEntry = function() end,
	destroy = function(terrain)
		destroys += 1
		if terrain then
			terrain:Destroy()
		end
	end,
})
WeatherService.useBroadcast(function(action, payload, to)
	table.insert(sent, { action = action, payload = payload })
end)
WeatherService.useMover(function(player, cf)
	player.Character:PivotTo(cf)
	return true
end)
WeatherService.useNest({
	open = function()
		return 3
	end,
	close = function()
		return 0
	end,
})
WeatherService.useRandom(nil)
WeatherService.useAutoConfig(nil)

local function sentOf(action)
	local n = 0
	for _, s in ipairs(sent) do
		if s.action == action then
			n += 1
		end
	end
	return n
end

-- Steps the event and the scheduler from `now` to `to`, `dt` apart (both, as
-- the service's loop does), and answers every non-nil scheduler result with
-- its time.
local function run(to, dt)
	local results = {}
	dt = dt or 1
	while now < to - 1e-9 do
		now = math.min(to, now + dt)
		WeatherService.Step(now)
		local r = WeatherService.AutoStep(now)
		if r then
			table.insert(results, { at = now, what = r })
		end
	end
	return results
end

-- Runs a started event to the end of its cleanup; answers the time it finished.
local function finishEvent()
	local guard = 0
	while WeatherService.State() ~= nil and guard < 4000 do
		guard += 1
		now += 0.5
		WeatherService.Step(now)
		WeatherService.AutoStep(now)
	end
	return now
end

local function fresh(at)
	WeatherService.Init()
	-- The real settings, the marks forgotten and the counts back to 0.
	WeatherService.useAutoConfig(nil)
	sent = {}
	players = { alice }
	buildOk = true
	if at then
		now = at
	end
end

-- The next mark on the spec's clock at least `ahead` seconds away.
local function markAfter(t, ahead)
	return (math.floor((t + (ahead or 0)) / HOUR) + 1) * HOUR
end

local function seededMode(mark)
	return WeatherService.PickMode(Random.new(mark):NextNumber(), A.ModeWeights)
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The owner's settings, and what a broken set does")
	--==========================================================================
	local good, why = WeatherService.ValidateAuto(A)
	check(good and A.Enabled == true and A.PeriodSeconds == 3600 and A.OffsetSeconds == 0 and A.DurationSeconds == 180
			and A.ModeWeights.rain == 0.9 and A.ModeWeights.thunder == 0.1 and NEXT_AT == "RainNextAt"
			and A.CheckSeconds == nil and A.Chance == nil and A.GuaranteeSeconds == nil,
		"GameConfig.Weather.Auto is the owner's 2026-10-16 set -- every 3600 s from 0 past (on the hour), 180 s, "
			.. "90/10, the next mark published as RainNextAt; the old draws' knobs are gone -- and validates", why)
	local function with(changes)
		local cfg = table.clone(A)
		cfg.ModeWeights = table.clone(A.ModeWeights)
		for k, v in pairs(changes) do
			cfg[k] = v
		end
		return cfg
	end
	local bad = {
		with({ Enabled = "yes" }), with({ PeriodSeconds = 0 }), with({ PeriodSeconds = -5 }),
		with({ PeriodSeconds = 0 / 0 }), with({ PeriodSeconds = math.huge }), with({ OffsetSeconds = -1 }),
		with({ OffsetSeconds = 3600 }), with({ OffsetSeconds = 0 / 0 }), with({ ModeWeights = { snow = 1 } }),
		with({ ModeWeights = { rain = 0, thunder = 0 } }), with({ ModeWeights = { rain = -1, thunder = 2 } }),
		with({ DurationSeconds = 10 }), with({ DurationSeconds = 180.5 }), with({ DurationSeconds = 99999 }),
		with({ PeriodSeconds = 600, DurationSeconds = 600 }),
	}
	local refused = 0
	for _, cfg in ipairs(bad) do
		if not WeatherService.ValidateAuto(cfg) then
			refused += 1
		end
	end
	check(refused == #bad, "every broken setting is refused (" .. #bad .. " kinds, a rain as long as its period "
		.. "among them)", refused .. " of " .. #bad)
	fresh()
	WeatherService.useAutoConfig(with({ PeriodSeconds = -1 }))
	local r = run(now + 2 * HOUR, 5)
	check(WeatherService.AutoState().enabled == false and #r == 0 and WeatherService.State() == nil
			and Workspace:GetAttribute(NEXT_AT) == nil,
		"a broken set turns the scheduler off: two hours, no weather, no countdown published")
	fresh()
	WeatherService.useAutoConfig(with({ Enabled = false }))
	r = run(now + 2 * HOUR, 5)
	check(#r == 0 and WeatherService.State() == nil and Workspace:GetAttribute(NEXT_AT) == nil,
		"Enabled = false: the same")
	WeatherService.useAutoConfig(nil)

	--==========================================================================
	say("2. The marks: on the hour")
	--==========================================================================
	local k = 139
	check(WeatherService.MarkAt(k * HOUR) == k * HOUR and WeatherService.MarkAt(k * HOUR + 5) == k * HOUR
			and WeatherService.MarkAt(k * HOUR + 3599.9) == k * HOUR and WeatherService.MarkAt(k * HOUR - 0.001) == (k - 1) * HOUR,
		"the latest mark at or before a time: the hour it is in")
	local shifted = with({ OffsetSeconds = 600 })
	check(WeatherService.MarkAt(k * HOUR + 599, shifted) == (k - 1) * HOUR + 600
			and WeatherService.MarkAt(k * HOUR + 600, shifted) == k * HOUR + 600,
		"an offset moves every mark by it (ten past, with 600)")
	local wrong = 0
	local t = 1792000000
	for _ = 1, 500 do
		t += 7919.37
		local d = os.date("!*t", WeatherService.MarkAt(t))
		if not (d.min == 0 and d.sec == 0) or WeatherService.MarkAt(t) > t or t - WeatherService.MarkAt(t) >= HOUR then
			wrong += 1
		end
	end
	check(wrong == 0, "on the real server clock (Unix seconds) every mark is a whole UTC hour -- the same moment on "
		.. "every server, and on the hour wherever the clock is a whole hour off UTC", wrong)

	--==========================================================================
	say("3. At the mark: one start, through the console's own path, for 180 s")
	--==========================================================================
	local H = markAfter(now, 1200)
	fresh(H - 600)
	r = run(H - 599, 1)
	check(#r == 0 and Workspace:GetAttribute(NEXT_AT) == H and WeatherService.AutoState().nextAt == H,
		"ten minutes before a mark: nothing, and the mark published for the sign", Workspace:GetAttribute(NEXT_AT))
	r = run(H - 1, 1)
	check(#r == 0 and WeatherService.State() == nil, "nothing before it")
	r = run(H, 1)
	local s = WeatherService.State()
	local mode = seededMode(H)
	check(#r == 1 and r[1].at == H and r[1].what == "started:" .. mode and s and s.mode == mode and s.state == "opening"
			and s.startedAt == H and s.endsAt == H + 180,
		"at the mark exactly: the mark's own weather (" .. mode .. "), for 180 s", r[1] and r[1].what)
	check(Workspace:GetAttribute(ATTR.State) == "opening" and Workspace:GetAttribute(ATTR.Mode) == mode
			and Workspace:GetAttribute(ATTR.EndsAt) == H + 180 and WeatherService.IncomeFactor() == SeedData.Rain.IncomeFactor
			and builds >= 1,
		"it is the console's event: the same attributes, the terrain built, the +25% paying")
	check(Workspace:GetAttribute(NEXT_AT) == H + HOUR and WeatherService.AutoState().usedMark == H
			and WeatherService.AutoState().starts == 1,
		"once it has started, the sign is told the next mark, an hour on")
	local seen = {}
	local guard = 0
	while WeatherService.State() ~= nil and guard < 4000 do
		guard += 1
		now += 0.5
		WeatherService.Step(now)
		local res = WeatherService.AutoStep(now)
		local st = WeatherService.State()
		if st then
			seen[st.state] = (seen[st.state] or 0) + 1
		end
		if res ~= nil then
			seen.bad = (seen.bad or 0) + 1
		end
	end
	check(seen.opening and seen.active and seen.closing and not seen.bad and sentOf(EVENTS.Opened) == 1,
		"opening, active and closing all pass with nothing more from the scheduler, the opening toast sent once")

	--==========================================================================
	say("4. One start a mark, every mark")
	--==========================================================================
	r = run(H + HOUR - 1, 5)
	check(#r == 0 and WeatherService.State() == nil, "nothing more until the next mark")
	local startsAt = {}
	for i = 1, 5 do
		r = run(H + i * HOUR, 1)
		if #r == 1 and r[1].at == H + i * HOUR and r[1].what == "started:" .. seededMode(H + i * HOUR) then
			table.insert(startsAt, i)
		end
		finishEvent()
		run(H + (i + 1) * HOUR - 1, 30)
	end
	check(#startsAt == 5 and WeatherService.AutoState().starts == 6,
		"five more hours, five more starts, each at its mark with its mark's weather", #startsAt)

	--==========================================================================
	say("5. The same weather on every server: a draw seeded by the mark")
	--==========================================================================
	local same, rain, N = 0, 0, 20000
	local base = 1792000000 - (1792000000 % HOUR)
	for i = 1, N do
		local mark = base + i * HOUR
		local a, b = Random.new(mark):NextNumber(), Random.new(mark):NextNumber()
		if a == b then
			same += 1
		end
		if WeatherService.PickMode(a) == "rain" then
			rain += 1
		end
	end
	check(same == N and math.abs(rain / N - 0.9) < 0.01,
		string.format("20,000 hours of marks: each mark's draw is the same wherever it is made, and Rain about 90%% "
			.. "of them (%.2f%%)", rain / N * 100))
	local src = sourceOf(Server, "WeatherService")
	check(string.find(src, "return Random.new(mark):NextNumber()", 1, true) ~= nil
			and string.find(src, "WeatherService.PickMode(draw(mark), cfg.ModeWeights)", 1, true) ~= nil
			and not string.find(src, "Random.new()", 1, true),
		"the scheduler's one draw is seeded by the mark alone: no unseeded Random anywhere in the service")
	check(WeatherService.PickMode(0) == "rain" and WeatherService.PickMode(0.8999999) == "rain"
			and WeatherService.PickMode(0.9) == "thunder" and WeatherService.PickMode(0.99999) == "thunder"
			and WeatherService.PickMode(0.3, { thunder = 1 }) == "thunder",
		"the mode draw, cumulative: under 0.9 Rain, from 0.9 a Thunderstorm")

	--==========================================================================
	say("6. Busy at the mark: it starts after, for what is left, and ends with everybody")
	--==========================================================================
	H = markAfter(now, 1200)
	fresh(H - 120)
	run(H - 61, 1)
	local okManual = WeatherService.StartRain(alice, 120)
	check(okManual and WeatherService.State() ~= nil, "the console's START RAIN a minute before the mark")
	r = run(H + 30, 0.5)
	check(#r == 0 and Workspace:GetAttribute(NEXT_AT) == H and WeatherService.AutoState().usedMark < H,
		"at the mark the console's rain is still falling: no second event, the mark still due (and still published)")
	-- The console's rain to its end, a step at a time: the step whose event
	-- step clears it is the step whose scheduler step starts the mark's.
	local startedAt, res = nil, nil
	for _ = 1, 4000 do
		now += 0.5
		WeatherService.Step(now)
		res = WeatherService.AutoStep(now)
		if res then
			startedAt = now
			break
		end
	end
	r = if res then { { at = startedAt, what = res } } else {}
	s = WeatherService.State()
	local ended = startedAt or now
	local left = math.floor(H + 180 - ended + 0.5)
	check(#r == 1 and r[1].what == "started:" .. seededMode(H) and s and s.endsAt - s.startedAt == left
			and math.abs(s.endsAt - (H + 180)) <= 0.5,
		string.format("the console's rain gone (%.1f s past the mark), the mark's weather starts for the %d s left of "
			.. "its window, ending with every other server's", ended - H, left), r[1] and r[1].what)
	finishEvent()

	--==========================================================================
	say("7. Nobody here at the mark")
	--==========================================================================
	H = markAfter(now, 1200)
	fresh(H - 30)
	players = {}
	r = run(H + 30, 1)
	check(#r == 0 and WeatherService.State() == nil and Workspace:GetAttribute(NEXT_AT) == H,
		"an empty server at the mark: no weather for nobody; the mark waits in its window")
	players = { alice }
	r = run(H + 31, 1)
	s = WeatherService.State()
	check(#r == 1 and s and s.startedAt == H + 31 and s.endsAt == H + 180,
		"the first arrival 31 s in: the mark's weather starts for the 149 s left of it", s and (s.endsAt - s.startedAt))
	finishEvent()
	H = markAfter(now, 1200)
	fresh(H - 30)
	run(H - 29, 1)
	players = {}
	r = run(H + 200, 0.25)
	local missedAt = r[1] and r[1].at - H
	check(#r == 1 and r[1].what == "missed" and missedAt >= 160 and missedAt <= 161
			and WeatherService.AutoState().missed == 1 and Workspace:GetAttribute(NEXT_AT) == H + HOUR,
		"nobody all through its window: MISSED once, under 20 s before its end (" .. tostring(missedAt) .. " s in); "
			.. "the sign told the next mark", r[1] and r[1].what)
	players = { alice }
	r = run(H + HOUR - 1, 10)
	check(#r == 0 and WeatherService.State() == nil, "an arrival after the window starts nothing until the next mark")

	--==========================================================================
	say("8. A server just up")
	--==========================================================================
	H = markAfter(now, 1200)
	fresh(H + 100)
	r = run(H + 101, 1)
	s = WeatherService.State()
	check(#r == 1 and s and s.endsAt == H + 180 and s.endsAt - s.startedAt == 79,
		"up 101 s after a mark: its first step starts that mark's weather for the 79 s left", s and (s.endsAt - s.startedAt))
	finishEvent()
	H = markAfter(now, 1200)
	fresh(H + 500)
	r = run(H + 501, 1)
	check(#r == 0 and WeatherService.State() == nil and WeatherService.AutoState().missed == 0
			and Workspace:GetAttribute(NEXT_AT) == H + HOUR,
		"up after a mark's window: no weather, nothing called missed, the next mark published")

	--==========================================================================
	say("9. A loop held up past whole marks never catches up")
	--==========================================================================
	H = markAfter(now, 1200)
	fresh(H - 10)
	run(H, 1)
	finishEvent()
	now = H + 3 * HOUR + 50
	WeatherService.Step(now)
	local single = WeatherService.AutoStep(now)
	s = WeatherService.State()
	check(single == "started:" .. seededMode(H + 3 * HOUR) and s and s.endsAt == H + 3 * HOUR + 180
			and WeatherService.AutoState().starts == 2 and WeatherService.AutoState().missed == 0,
		"held up to 50 s past the third mark: one start, that mark's, for its 130 s; the two before are gone, "
			.. "not caught up", single)
	finishEvent()
	now = H + 6 * HOUR + 500
	single = WeatherService.AutoStep(now)
	check(single == "missed" and WeatherService.AutoState().missed == 1 and WeatherService.State() == nil
			and Workspace:GetAttribute(NEXT_AT) == H + 7 * HOUR,
		"held up past a mark's window: that one mark missed, once; the next published", single)

	--==========================================================================
	say("10. A start that fails, and a biome that does not build")
	--==========================================================================
	H = markAfter(now, 1200)
	fresh(H - 5)
	local realStart = WeatherService.StartWeather
	local calls = 0
	WeatherService.StartWeather = function()
		calls += 1
		error("test failure")
	end
	r = run(H, 1)
	local state = WeatherService.AutoState()
	check(#r == 1 and r[1].what == "failed" and calls == 1 and state.failures == 1
			and string.find(tostring(state.lastFailure), "test failure", 1, true) ~= nil and state.usedMark == H
			and Workspace:GetAttribute(NEXT_AT) == H + HOUR,
		"a start that throws: one try, one failure recorded, the mark used", r[1] and r[1].what)
	r = run(H + 300, 0.25)
	check(#r == 0 and calls == 1, "no retry inside its window -- 1,200 steps, no spam", calls)
	r = run(H + HOUR, 1)
	check(#r == 1 and r[1].what == "failed" and calls == 2, "the next mark tries again, once", calls)
	WeatherService.StartWeather = realStart
	H = markAfter(now, 1200)
	fresh(H - 5)
	buildOk = false
	r = run(H, 1)
	s = WeatherService.State()
	check(#r == 1 and string.sub(r[1].what, 1, 8) == "started:" and s and s.ready == false,
		"a biome that does not build is the existing event, entrance shut: the rain and the bonus still run")
	local f = finishEvent()
	check(WeatherService.State() == nil and destroys >= 1 and f > H,
		"and it ends and cleans up as it always did")
	buildOk = true

	--==========================================================================
	say("11. The console's weather and the Enchanted Mist")
	--==========================================================================
	H = markAfter(now, 1200)
	fresh(H + 600)
	run(H + 601, 1)
	local okStart = WeatherService.StartThunderstorm(alice, 60)
	check(okStart and WeatherService.State().mode == "thunder" and Workspace:GetAttribute(NEXT_AT) == H + HOUR,
		"the console's weather between marks still works, and leaves the next mark where it was")
	finishEvent()
	check(WeatherService.EndRain(alice), "END with nothing running stays harmless")
	check(not string.find(src, "EnchantedMist", 1, true) and not string.find(src, "PodRush", 1, true),
		"the hourly weather never waits for the Mist or a Pod Rush (the owner, 2026-10-16: both at once)")

	--==========================================================================
	say("12. One loop, no stale state, nothing a client can reach")
	--==========================================================================
	H = markAfter(now, 1200)
	fresh(H - 100)
	run(H - 99, 1)
	check(WeatherService.AutoState().usedMark ~= nil and Workspace:GetAttribute(NEXT_AT) == H, "(the scheduler is running)")
	WeatherService.Init()
	check(WeatherService.AutoState().usedMark == nil and WeatherService.AutoState().nextAt == nil
			and Workspace:GetAttribute(NEXT_AT) == nil,
		"Init leaves no mark and no countdown behind")
	run(now + 1, 1)
	WeatherService.Stop()
	check(WeatherService.AutoState().usedMark == nil and Workspace:GetAttribute(NEXT_AT) == nil,
		"nor does Stop")
	check(count(src, "task.spawn(") == 1 and count(src, "pcall(WeatherService.AutoStep, now)") == 1
			and string.find(src, "while running and mine == generation do", 1, true) ~= nil
			and count(src, "resetWindow()") >= 6,
		"one loop for the event AND the scheduler, retired by a new generation; Init, Start, Stop, a switched-off "
			.. "scheduler and new settings forget the marks")
	check(string.find(src, "every hour on the hour), the same moment \"", 1, true) ~= nil
			and string.find(src, "Automatic weather: the %s mark was missed", 1, true) ~= nil,
		"its Ready line says every hour on the hour; a missed mark is logged")
	check(not string.find(src, "OnServerEvent", 1, true) and not string.find(src, "MessagingService", 1, true),
		"WeatherService listens to no remote and nothing cross-server: the clock alone keeps servers together")
	local reached = {}
	for _, d in ipairs(Server:GetDescendants()) do
		if (d:IsA("ModuleScript") or d:IsA("Script")) and d.Name ~= "WeatherService" then
			local text = sourceOf(d.Parent, d.Name)
			if string.find(text, "AutoStep", 1, true) or string.find(text, "useAutoConfig", 1, true)
				or string.find(text, "useRandom", 1, true) then
				table.insert(reached, d:GetFullName())
			end
		end
	end
	check(#reached == 0, "no other server script calls the scheduler or its seams", table.concat(reached, ", "))
	-- Every admin's since 2026-10-07 (the owner's before): the allowlist is
	-- Handle's first check, and the weather is routed only after it.
	local admin = sourceOf(Server, "AdminService")
	local handleAt = string.find(admin, "function AdminService.Handle(", 1, true)
	local gateAt = handleAt and string.find(admin, "if not AdminService.IsAdmin(sender) then", handleAt, true)
	local routeAt = gateAt
		and string.find(admin, 'if action == "Weather" then\n\t\treturn weather(sender, targetId, amount)', gateAt, true)
	check(routeAt ~= nil, "the console's weather still passes AdminService's allowlist first, and only then the event's")
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw: " .. tostring(err))
end

WeatherService.useClock(nil)
WeatherService.usePlayers(nil)
WeatherService.useRandom(nil)
WeatherService.useTerrain(nil)
WeatherService.useBroadcast(nil)
WeatherService.useMover(nil)
WeatherService.useNest(nil)
WeatherService.useAutoConfig(nil)
pcall(WeatherService.Init)
scratch:Destroy()

local verdict = string.format("AutoWeatherSpec: %d passed, %d failed", pass, fail)
return verdict .. "\n" .. table.concat(out, "\n")
