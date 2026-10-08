--!nocheck
--==============================================================================
-- Steal a Seed :: AutoWeatherSpec (2026-10-05)
--
-- Automatic weather (WeatherService's scheduler; GameConfig.Weather.Auto): the
-- owner's settings validate and broken ones turn it off; no check before the
-- first five minutes of a populated clear window; a failed draw moves to the
-- next check on the window's grid; a successful one starts the drawn mode for
-- 180 s through the console's own path; the 60-minute guarantee (since the
-- owner's lower rate of the same day: 5% a check, 90/10, not 15% / 80/20 / 30
-- minutes) starts weather when every draw failed, and 30 minutes is an
-- ordinary check; nothing is drawn in any state of any event, for an
-- empty server, or more than once per step however late; the console's weather
-- resets the window; a failed start waits for the next check; Init, Start and
-- Stop keep one loop and no stale window. Edit mode, on the spec's own clock,
-- with a queue of draws -- no real minutes pass.
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
-- THE SEAMS: a clock, a player list, a terrain that counts, a recording remote,
-- a nest that lays three, and a queue of draws (an empty queue draws 0.99: no
-- weather).
--==============================================================================
local now = 500000
local alice = standIn("Alice", 1, Vector3.new(0, 3, 0))
local players = { alice }
local draws = {}
local drawCount = 0
local builds, destroys, sent = 0, 0, {}
local buildOk = true
WeatherService.useClock(function()
	return now
end)
WeatherService.usePlayers(function()
	return players
end)
WeatherService.useRandom(function()
	drawCount += 1
	local v = table.remove(draws, 1)
	return if v == nil then 0.99 else v
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

local function fresh()
	WeatherService.Init()
	draws, drawCount, sent = {}, 0, {}
	players = { alice }
	buildOk = true
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The owner's settings, and what a broken set does")
	--==========================================================================
	local good, why = WeatherService.ValidateAuto(A)
	check(good and A.Enabled == true and A.CheckSeconds == 300 and A.Chance == 0.05 and A.DurationSeconds == 180
			and A.GuaranteeSeconds == 3600 and A.ModeWeights.rain == 0.9 and A.ModeWeights.thunder == 0.1,
		"GameConfig.Weather.Auto is the approved set -- 300 s, 5%, 90/10, 180 s, sure at 3600 s -- and validates", why)
	local function with(changes)
		local cfg = table.clone(A)
		cfg.ModeWeights = table.clone(A.ModeWeights)
		for k, v in pairs(changes) do
			cfg[k] = v
		end
		return cfg
	end
	local bad = {
		with({ Enabled = "yes" }), with({ CheckSeconds = 0 }), with({ CheckSeconds = -5 }), with({ Chance = 1.5 }),
		with({ Chance = -0.1 }), with({ Chance = 0 / 0 }), with({ ModeWeights = { snow = 1 } }),
		with({ ModeWeights = { rain = 0, thunder = 0 } }), with({ ModeWeights = { rain = -1, thunder = 2 } }),
		with({ DurationSeconds = 10 }), with({ DurationSeconds = 180.5 }), with({ DurationSeconds = 99999 }),
		with({ GuaranteeSeconds = 100 }), with({ GuaranteeSeconds = math.huge }),
	}
	local refused = 0
	for _, cfg in ipairs(bad) do
		if not WeatherService.ValidateAuto(cfg) then
			refused += 1
		end
	end
	check(refused == #bad, "every broken setting is refused (" .. #bad .. " kinds)", refused .. " of " .. #bad)
	WeatherService.useAutoConfig(with({ Chance = 2 }))
	fresh()
	local r = run(now + 2400, 5)
	check(WeatherService.AutoState().enabled == false and #r == 0 and drawCount == 0 and WeatherService.State() == nil,
		"a broken set turns the scheduler off: 40 minutes, no window, no draw, no weather")
	WeatherService.useAutoConfig(with({ Enabled = false }))
	fresh()
	r = run(now + 2400, 5)
	check(#r == 0 and drawCount == 0 and WeatherService.State() == nil, "Enabled = false: the same")
	WeatherService.useAutoConfig(nil)

	--==========================================================================
	say("2. No check before five minutes; failed draws keep the window's grid; 30 minutes forces nothing")
	--==========================================================================
	fresh()
	local t0 = now + 1
	r = run(t0, 1)
	check(#r == 1 and r[1].what == "armed" and WeatherService.AutoState().quietSince == t0
			and WeatherService.AutoState().nextCheckAt == t0 + 300,
		"the first step with a player and clear weather opens the window, the first check 300 s on")
	r = run(t0 + 299, 1)
	check(#r == 0 and drawCount == 0 and WeatherService.State() == nil, "nothing is drawn before 300 s", drawCount)
	r = run(t0 + 3300, 1)
	local times = {}
	local at30 = nil
	for _, x in ipairs(r) do
		table.insert(times, string.format("%s@%d", x.what, x.at - t0))
		if x.at == t0 + 1800 then
			at30 = x.what
		end
	end
	check(#r == 11 and drawCount == 11 and r[1].at == t0 + 300 and r[11].at == t0 + 3300 and at30 == "clear"
			and WeatherService.AutoState().nextCheckAt == t0 + 3600 and WeatherService.State() == nil,
		"eleven failed draws at 5, 10 .. 55 minutes -- the old 30-minute guarantee is an ordinary draw now, and "
			.. "forces nothing -- the next check at 60", table.concat(times, " "))

	--==========================================================================
	say("3. The 60-minute guarantee, with every draw failed")
	--==========================================================================
	draws = { 0.95 }
	r = run(t0 + 3600, 1)
	local s = WeatherService.State()
	check(#r == 1 and r[1].what == "started:thunder" and r[1].at == t0 + 3600 and drawCount == 12
			and s and s.mode == "thunder" and s.state == "opening" and s.endsAt - s.startedAt == 180,
		"at 60 minutes exactly one start, without a chance draw: one mode draw (0.95 -> Thunderstorm), 180 s",
		r[1] and (r[1].what .. " " .. drawCount))
	check(Workspace:GetAttribute(ATTR.State) == "opening" and Workspace:GetAttribute(ATTR.Mode) == "thunder"
			and Workspace:GetAttribute(ATTR.EndsAt) == s.endsAt and WeatherService.IncomeFactor() == SeedData.Rain.IncomeFactor
			and builds >= 1,
		"it is the console's event: the same attributes, the terrain built, the +25% paying")

	--==========================================================================
	say("4. Nothing is drawn in any state of an event; the window reopens after cleanup")
	--==========================================================================
	local seen = {}
	local before = drawCount
	local guard = 0
	while WeatherService.State() ~= nil and guard < 4000 do
		guard += 1
		now += 0.5
		WeatherService.Step(now)
		local res = WeatherService.AutoStep(now)
		local st = WeatherService.State()
		if st then
			seen[st.state] = (seen[st.state] or 0) + 1
			if res ~= nil or WeatherService.AutoState().quietSince ~= nil then
				seen.bad = (seen.bad or 0) + 1
			end
		end
	end
	local finishedAt = now
	check(seen.opening and seen.active and seen.closing and not seen.bad and drawCount == before and sentOf(EVENTS.Opened) == 1,
		"opening, active and closing all passed with no window and no draw, the opening toast sent once",
		string.format("opening %s active %s closing %s bad %s draws %d", tostring(seen.opening), tostring(seen.active),
			tostring(seen.closing), tostring(seen.bad), drawCount - before))
	-- The loop steps the event, then the scheduler: the step that removes the
	-- biome is the step that opens the new window.
	check(WeatherService.AutoState().quietSince == finishedAt
			and WeatherService.AutoState().nextCheckAt == finishedAt + 300,
		"the step that finishes the cleanup opens a fresh window; its first check 300 s later")
	r = run(finishedAt + 299, 1)
	check(#r == 0 and drawCount == before, "no draw before that check")
	draws = { 0.04, 0.5 }
	r = run(finishedAt + 300, 1)
	s = WeatherService.State()
	check(#r == 1 and r[1].what == "started:rain" and drawCount == before + 2 and s and s.mode == "rain"
			and s.endsAt - s.startedAt == 180,
		"that check is an ordinary one: 0.04 is under 0.05, its mode draw 0.5 is Rain, 180 s", r[1] and r[1].what)
	finishEvent()

	--==========================================================================
	say("4b. The guarantee draws its mode 90/10 too")
	--==========================================================================
	-- A mode draw of 0.85: a Thunderstorm under the old 80/20, Rain under 90/10.
	fresh()
	local tg = now + 1
	run(tg, 1)
	r = run(tg + 3300, 1)
	draws = { 0.85 }
	local forced = run(tg + 3600, 1)
	s = WeatherService.State()
	check(#r == 11 and #forced == 1 and forced[1].what == "started:rain" and drawCount == 12 and s and s.mode == "rain",
		"eleven misses, then at 60 minutes the one mode draw 0.85 starts Rain -- the 90/10 split, not the old 80/20",
		forced[1] and forced[1].what)
	finishEvent()

	--==========================================================================
	say("5. A successful check at the 5% threshold, and the 90/10 draw")
	--==========================================================================
	fresh()
	local tc = now + 1
	run(tc, 1)
	draws = { 0.05 }
	r = run(tc + 300, 1)
	check(#r == 1 and r[1].what == "clear" and drawCount == 1 and WeatherService.State() == nil,
		"a chance draw of exactly 0.05 is no weather, and no mode is drawn (a start needs a draw under 0.05)",
		r[1] and r[1].what)
	draws = { 0.10 }
	r = run(tc + 600, 1)
	check(#r == 1 and r[1].what == "clear" and drawCount == 2 and WeatherService.State() == nil,
		"nor is 0.10, which started weather under the old 15%", r[1] and r[1].what)
	draws = { 0.0499999, 0.8999999 }
	r = run(tc + 900, 1)
	s = WeatherService.State()
	check(#r == 1 and r[1].what == "started:rain" and drawCount == 4 and s and s.mode == "rain"
			and s.endsAt - s.startedAt == 180,
		"0.0499999 starts weather at the next check; its mode draw 0.8999999 is Rain; 180 s", r[1] and r[1].what)
	local fc = finishEvent()
	draws = { 0.0499999, 0.9 }
	r = run(fc + 300, 1)
	s = WeatherService.State()
	check(#r == 1 and r[1].what == "started:thunder" and drawCount == 6 and s and s.mode == "thunder"
			and s.endsAt - s.startedAt == 180,
		"an ordinary check's Thunderstorm: a hit, then a mode draw of exactly 0.9", r[1] and r[1].what)
	finishEvent()
	check(WeatherService.PickMode(0) == "rain" and WeatherService.PickMode(0.85) == "rain"
			and WeatherService.PickMode(0.8999999) == "rain" and WeatherService.PickMode(0.9) == "thunder"
			and WeatherService.PickMode(0.99999) == "thunder" and WeatherService.PickMode(0.3, { thunder = 1 }) == "thunder",
		"the mode draw, cumulative: under 0.9 Rain, from 0.9 a Thunderstorm")
	local rng = Random.new(20261005)
	local rain = 0
	for _ = 1, 20000 do
		if WeatherService.PickMode(rng:NextNumber()) == "rain" then
			rain += 1
		end
	end
	check(math.abs(rain / 20000 - 0.9) < 0.01, "20,000 uniform mode draws: Rain about 90%", rain / 20000)
	-- The two stages together, as an ordinary check draws them.
	local total = A.ModeWeights.rain + A.ModeWeights.thunder
	local pRain, pThunder = A.Chance * A.ModeWeights.rain / total, A.Chance * A.ModeWeights.thunder / total
	local got = { rain = 0, thunder = 0, none = 0 }
	local N = 400000
	for _ = 1, N do
		if rng:NextNumber() < A.Chance then
			local mode = WeatherService.PickMode(rng:NextNumber())
			got[mode] += 1
		else
			got.none += 1
		end
	end
	check(math.abs(pRain - 0.045) < 1e-12 and math.abs(pThunder - 0.005) < 1e-12 and math.abs(1 - A.Chance - 0.95) < 1e-12
			and math.abs(got.rain / N - 0.045) < 0.0015 and math.abs(got.thunder / N - 0.005) < 0.0005
			and math.abs(got.none / N - 0.95) < 0.0015,
		string.format("an ordinary check: 4.5%% Rain, 0.5%% Thunderstorm, 95%% nothing -- a draw for weather, then one for "
			.. "which (sample of %d: %.2f%% / %.3f%% / %.2f%%)", N, got.rain / N * 100, got.thunder / N * 100,
			got.none / N * 100))

	--==========================================================================
	say("5b. Every way a window ends, on the scheduler's own clock; the expected wait")
	--==========================================================================
	-- k - 1 misses then a hit start weather at check k (k = 1 .. 11); eleven
	-- misses reach the guarantee, check 12. StartWeather is a stand-in that only
	-- says yes, so no event runs; the scheduler's own start times, weighted by
	-- the 5% chance, are the expected clear wait.
	local realStartWeather = WeatherService.StartWeather
	local asked = {}
	WeatherService.StartWeather = function(by, seconds, mode)
		table.insert(asked, { by = by, seconds = seconds, mode = mode })
		return true, "ok"
	end
	local waits, wrong = {}, {}
	for k = 1, 12 do
		fresh()
		asked = {}
		local tk = now + 1
		run(tk, 1)
		for _ = 1, k - 1 do
			table.insert(draws, 0.5)
		end
		if k <= 11 then
			table.insert(draws, 0.0499999)
		end
		table.insert(draws, 0.5)
		local res = run(tk + 300 * k, 300)
		local last = res[#res]
		waits[k] = if last then last.at - tk else nil
		local a = asked[1]
		if not (#res == k and last.what == "started:rain" and waits[k] == 300 * k and #draws == 0
			and drawCount == (if k <= 11 then k + 1 else 12) and #asked == 1 and a.seconds == 180 and a.mode == "rain"
			and a.by and a.by.Name == "automatic weather")
		then
			table.insert(wrong, string.format("k=%d: %d results, last %s at %s, %d draws, %d left, %d asked", k, #res,
				tostring(last and last.what), tostring(waits[k]), drawCount, #draws, #asked))
		end
	end
	WeatherService.StartWeather = realStartWeather
	check(#wrong == 0,
		"k - 1 misses then a hit start at check k, 300k s in, for k = 1 .. 11; eleven misses start at 3600 s without "
			.. "a chance draw -- each one call of StartWeather, as automatic weather, for 180 s", table.concat(wrong, "; "))
	local fromScheduler = 0
	for k = 1, 11 do
		fromScheduler += (waits[k] or 0) * A.Chance * (1 - A.Chance) ^ (k - 1)
	end
	fromScheduler += (waits[12] or 0) * (1 - A.Chance) ^ 11
	local expected = 0
	for k = 1, 11 do
		expected += 300 * k * 0.05 * 0.95 ^ (k - 1)
	end
	expected += 3600 * 0.95 ^ 11
	check(math.abs(fromScheduler - expected) < 1e-6 and math.abs(expected / 60 - 45.964) < 0.001
			and math.abs(0.95 ^ 11 - 0.5688) < 0.0001,
		string.format("the expected clear wait is %.2f minutes (it was 20.76); eleven misses, so the guarantee, end "
			.. "%.1f%% of windows", fromScheduler / 60, (1 - A.Chance) ^ 11 * 100), fromScheduler / 60)

	--==========================================================================
	say("6. The console's weather resets the window")
	--==========================================================================
	fresh()
	local t1 = now + 1
	run(t1, 1)
	run(t1 + 250, 1)
	local okManual = WeatherService.StartRain(alice, 60)
	check(okManual and WeatherService.State() ~= nil, "the console's START RAIN still works mid-window")
	WeatherService.AutoStep(now)
	check(WeatherService.AutoState().quietSince == nil, "and closes the window at once")
	local f = finishEvent()
	before = drawCount
	check(WeatherService.AutoState().quietSince == f and WeatherService.AutoState().nextCheckAt == f + 300,
		"after it has gone, a fresh window -- its first check 300 s after the cleanup, not on the old grid")
	r = run(f + 299, 1)
	check(#r == 0 and drawCount == before, "nothing drawn in between (the old window's check would have been at "
		.. (t1 + 300 - f) .. " s)")
	local okEnd = WeatherService.EndRain(alice)
	check(okEnd, "END with nothing running stays harmless")

	--==========================================================================
	say("7. An empty server")
	--==========================================================================
	fresh()
	local t2 = now + 1
	run(t2, 1)
	run(t2 + 100, 1)
	players = {}
	r = run(t2 + 700, 5)
	check(#r == 0 and drawCount == 0 and WeatherService.AutoState().quietSince == nil and WeatherService.State() == nil,
		"nobody here: the window closes, no draw at the old 300-s check, no weather", drawCount)
	players = { alice }
	r = run(t2 + 701, 1)
	check(#r == 1 and r[1].what == "armed" and WeatherService.AutoState().nextCheckAt == t2 + 1001,
		"the next arrival starts a fresh window: no immediate roll, the first check 300 s later")

	--==========================================================================
	say("8. One attempt per step, however late")
	--==========================================================================
	fresh()
	local t3 = now + 1
	run(t3, 1)
	now = t3 + 1000
	local single = WeatherService.AutoStep(now)
	check(single == "clear" and drawCount == 1 and WeatherService.AutoState().nextCheckAt == t3 + 1200,
		"3.3 checks overdue: exactly one draw, the next check at the grid's next point (1200 s)",
		tostring(single) .. " " .. drawCount .. " " .. tostring(WeatherService.AutoState().nextCheckAt - t3))
	r = run(t3 + 1199, 0.5)
	check(#r == 0 and drawCount == 1, "no catch-up draws after it")
	fresh()
	local t4 = now + 1
	run(t4, 1)
	now = t4 + 5000
	draws = { 0.1 }
	single = WeatherService.AutoStep(now)
	check(single == "started:rain" and drawCount == 1, "long past the guarantee: one attempt, the guarantee's, one draw",
		tostring(single) .. " " .. drawCount)
	finishEvent()

	--==========================================================================
	say("9. A start that fails, and a biome that does not build")
	--==========================================================================
	fresh()
	local realStart = WeatherService.StartWeather
	local calls = 0
	WeatherService.StartWeather = function()
		calls += 1
		error("test failure")
	end
	local t5 = now + 1
	run(t5, 1)
	draws = { 0.01, 0.5 }
	r = run(t5 + 300, 1)
	local state = WeatherService.AutoState()
	check(#r == 1 and r[1].what == "failed" and calls == 1 and state.failures == 1
			and string.find(tostring(state.lastFailure), "test failure", 1, true) ~= nil and state.nextCheckAt == t5 + 600,
		"a start that throws: one try, one failure recorded, the next try at the next check", r[1] and r[1].what)
	r = run(t5 + 599, 0.25)
	check(#r == 0 and calls == 1, "no retry before it -- 1,200 steps, no spam", calls)
	draws = { 0.01, 0.5 }
	r = run(t5 + 600, 1)
	check(#r == 1 and r[1].what == "failed" and calls == 2, "one retry at the next check", calls)
	WeatherService.StartWeather = realStart
	fresh()
	buildOk = false
	local t6 = now + 1
	run(t6, 1)
	draws = { 0.01, 0.5 }
	r = run(t6 + 300, 1)
	s = WeatherService.State()
	check(#r == 1 and r[1].what == "started:rain" and s and s.ready == false,
		"a biome that does not build is the existing event, entrance shut: the rain and the bonus still run")
	f = finishEvent()
	check(WeatherService.State() == nil and destroys >= 1 and WeatherService.AutoState().quietSince == f,
		"and it ends and cleans up as it always did, the window reopening as it finishes")
	buildOk = true

	--==========================================================================
	say("10. One loop, no stale window, nothing a client can reach")
	--==========================================================================
	fresh()
	run(now + 1, 1)
	check(WeatherService.AutoState().quietSince ~= nil, "(a window is open)")
	WeatherService.Init()
	check(WeatherService.AutoState().quietSince == nil, "Init leaves no window behind")
	local src = sourceOf(Server, "WeatherService")
	check(count(src, "task.spawn(") == 1 and count(src, "pcall(WeatherService.AutoStep, now)") == 1
			and string.find(src, "while running and mine == generation do", 1, true) ~= nil
			and count(src, "resetWindow()") >= 5,
		"one loop for the event AND the scheduler, retired by a new generation; Init, Start and Stop reset the window")
	check(not string.find(src, "OnServerEvent", 1, true) and not string.find(src, "MessagingService", 1, true),
		"WeatherService listens to no remote and nothing cross-server")
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
