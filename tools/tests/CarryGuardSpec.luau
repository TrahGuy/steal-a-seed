--!strict
-- CarryGuardSpec: a pod cannot travel faster than its carrier is allowed to run.
-- Honest runs, network stalls and the server's own small moves always pass; a
-- teleport fails at once and a speed hack within seconds. Pure: no character,
-- no services started, no profile.
local Guard = require(game.ServerScriptService.SeedGameServer.CarryGuard)

local pass = 0
local failures: { string } = {}
local function check(ok: boolean, message: string)
	if ok then pass += 1 else table.insert(failures, message) end
end

-- Walks a straight line at `speed` studs/s for `seconds`, with positions
-- arriving every `every` seconds (bursty, like replication), against a server
-- that has set WalkSpeed = `walk`. Returns whether every observation passed,
-- and the time of the first rejection.
local function run(walk: number, speed: number, seconds: number, every: number): (boolean, number?)
	local start = Vector3.new(-22, 3, -415)
	local state = Guard.new(start)
	local frame = 1 / 60
	local t = 0
	local nextReport = every
	local pos = start
	while t < seconds do
		t += frame
		-- Time passes every server frame; the position changes only when an
		-- update arrives.
		if t >= nextReport then
			nextReport += every
			pos = start + Vector3.new(0, 0, speed * t)
		end
		if not Guard.step(state, pos, walk, frame) then
			return false, t
		end
	end
	return true, nil
end

local ok, err = pcall(function()
	--==========================================================================
	-- HONEST RUNS PASS
	--==========================================================================
	check((run(16 * 0.6, 16 * 0.6, 60, 1 / 30)), "a new player hauling a heavy pod (WalkSpeed 9.6) runs 60 s untouched")
	check((run(150, 150, 20, 1 / 30)), "a maxed player at WalkSpeed 150 runs 20 s untouched")
	check((run(26, 26, 30, 0.25)), "updates arriving only four times a second still pass")
	check((run(26, 26 * 1.3, 30, 1 / 30)), "30% over WalkSpeed (client lag, a WalkSpeed change in flight) passes")

	--==========================================================================
	-- A NETWORK STALL IS PAID FOR BY THE TIME THAT PASSED
	--==========================================================================
	do
		local state = Guard.new(Vector3.zero)
		for _ = 1, 180 do Guard.step(state, Vector3.zero, 26, 1 / 60) end -- 3 s, no updates
		check((Guard.step(state, Vector3.new(0, 0, 26 * 3), 26, 1 / 60)),
			"3 s of running delivered in one update after a 3 s stall passes")
	end
	do
		local state = Guard.new(Vector3.zero)
		for _ = 1, 480 do Guard.step(state, Vector3.zero, 26, 1 / 60) end -- 8 s stall
		check(not (Guard.step(state, Vector3.new(0, 0, 26 * 8), 26, 1 / 60)),
			"a stall longer than CapSeconds is capped: 8 s of running in one update is put back")
	end

	--==========================================================================
	-- TELEPORTS FAIL AT ONCE
	--==========================================================================
	do
		-- The Starbloom nest to Plot_01: the exploit this exists for.
		local state = Guard.new(Vector3.new(-22, 3, -1615))
		local accepted, moved = Guard.step(state, Vector3.new(-97, 3, -60), 150, 1 / 60)
		check(not accepted and moved > 1500, "a Starbloom-to-plot teleport fails even at WalkSpeed 150")
		check(state.at == Vector3.new(-22, 3, -1615),
			"a rejected step leaves the anchor where the server last saw them")
	end
	do
		local state = Guard.new(Vector3.new(-22, 3, -415))
		check(not (Guard.step(state, Vector3.new(-22, 3, -315), 26, 1 / 60)),
			"a 100-stud hop straight after the take fails")
	end
	do
		-- What the server actually saw in Play on 2026-09-21: a client teleport
		-- arrives as ~10 studs a frame, not one jump. The guard may accept the
		-- slack's worth of it and no more.
		local start = Vector3.new(0, 3, -235)
		local state = Guard.new(start)
		local pos = start
		local accepted = 0
		for _ = 1, 12 do
			pos += Vector3.new(0, 0, 10)
			if Guard.step(state, pos, 16, 1 / 60) then accepted += 1 else break end
		end
		local gained = (state.at - start).Magnitude
		check(gained <= Guard.SlackStuds + 1, string.format(
			"a teleport seen as 10 studs a frame gains at most the slack (%.0f studs)", gained))
	end
	do
		-- A carry that starts moments after the last one gets no slack.
		local state = Guard.new(Vector3.zero, true)
		check(state.budget == 0 and not (Guard.step(state, Vector3.new(0, 0, 10), 16, 1 / 60)),
			"a re-take within the cooldown starts with nothing saved")
	end
	do
		-- The most a patient exploiter can save: CapSeconds of travel.
		local state = Guard.new(Vector3.zero)
		for _ = 1, 600 do Guard.step(state, Vector3.zero, 26, 1 / 60) end -- wait 10 s
		local cap = Guard.capFor(26)
		check((Guard.step(state, Vector3.new(0, 0, cap - 1), 26, 0)), "standing still saves up to exactly the cap")
		check(not (Guard.step(state, Vector3.new(0, 0, cap - 1 + 10), 26, 0)),
			"and not a stud more: saved travel is spent, not refilled")
		check(cap < 200, string.format("the cap at WalkSpeed 26 is %.0f studs, a few seconds of running", cap))
	end

	--==========================================================================
	-- SPEED HACKS FAIL WITHIN SECONDS
	--==========================================================================
	local doubled, at = run(26, 52, 30, 1 / 30)
	check(not doubled and at ~= nil and at < 5,
		string.format("double speed is put back within 5 s (at %.2f s)", at or -1))
	local hacked, at2 = run(26, 150, 30, 1 / 30)
	check(not hacked and at2 ~= nil and at2 < 1,
		string.format("WalkSpeed 150 on a 26 carrier is put back within 1 s (at %.2f s)", at2 or -1))

	-- A HACKER WHO KEEPS GOING AFTER EVERY CORRECTION. The client adopts the
	-- put-back position and runs again at 100 studs/s. Over 20 s the net ground
	-- gained must stay at or under what WalkSpeed 26 allows (1.35x) plus the
	-- starting slack -- never the hack's own speed.
	do
		local walk, hackSpeed, frame = 26, 100, 1 / 60
		local start = Vector3.new(0, 3, -1615)
		local state = Guard.new(start)
		local client = start
		local corrections = 0
		for _ = 1, 20 * 60 do
			client += Vector3.new(0, 0, hackSpeed * frame)
			if not Guard.step(state, client, walk, frame) then
				corrections += 1
				Guard.reset(state, state.at)
				client = state.at
			end
		end
		local gained = (state.at - start).Magnitude
		local allowed = walk * Guard.Tolerance * 20 + Guard.SlackStuds
		check(gained <= allowed and corrections > 0, string.format(
			"a hacker running 100 studs/s through corrections nets %.0f studs in 20 s (allowed %.0f, a hack would be 2000)",
			gained, allowed))
	end

	--==========================================================================
	-- THE SERVER'S OWN SMALL MOVES, AND GRAVITY
	--==========================================================================
	do
		-- Rooted by a trap (WalkSpeed 0), then pulled the Starlock's 8 studs.
		local state = Guard.new(Vector3.zero)
		check((Guard.step(state, Vector3.new(8, 0, 0), 0, 1 / 60)), "a Starlock pull of 8 studs while rooted passes")
	end
	do
		-- A Dunesnap trip: 7 studs a second for about 1.1 s, pod kept.
		local state = Guard.new(Vector3.zero)
		local accepted = true
		for i = 1, 66 do
			if not Guard.step(state, Vector3.new(0, 0, 7 * i / 60), 0, 1 / 60) then accepted = false end
		end
		check(accepted, "a Dunesnap trip tumble passes even at WalkSpeed 0")
	end
	do
		local state = Guard.new(Vector3.new(0, 50, 0))
		check((Guard.step(state, Vector3.new(0, -40, 0), 16, 1 / 60)), "falling 90 studs is not travel")
	end

	--==========================================================================
	-- BAD INPUT
	--==========================================================================
	do
		local state = Guard.new(Vector3.zero)
		local nan = 0 / 0
		check(not (Guard.step(state, Vector3.new(nan, 0, 0), 26, 1 / 60)), "a NaN position is rejected")
		check((Guard.step(state, Vector3.new(1, 0, 0), nan, nan)),
			"a NaN WalkSpeed or dt counts as zero, not as infinite")
		Guard.reset(state, Vector3.new(5, 0, 5))
		check(state.at == Vector3.new(5, 0, 5) and state.budget == 0,
			"reset re-anchors with nothing saved, so a correction grants no free travel")
	end

	--==========================================================================
	-- CARRYSERVICE STILL ASKS THE GUARD
	--
	-- A text check, because the wiring is the regression that matters: a guard
	-- nobody calls is no guard. The live check is recorded in KB/HANDOFF.
	--==========================================================================
	local source = (game.ServerScriptService.SeedGameServer.CarryService :: any).Source :: string
	check(source:find("guards[player] = CarryGuard.new(root.Position,", 1, true) ~= nil,
		"the budget starts at the take, where the pod was picked up")
	check(source:find("CarryGuard.SlackCooldownSeconds", 1, true) ~= nil,
		"a quick re-take is started without slack")
	check(source:find("if checkCarrier(player, 0) then", 1, true) ~= nil,
		"the bank loop asks the guard before it banks")
	check(source:find("RunService.Heartbeat:Connect(function(dt: number)", 1, true) ~= nil
		and source:find("checkCarrier(player, dt)", 1, true) ~= nil,
		"every carrier is checked every frame")
end)
if not ok then table.insert(failures, tostring(err)) end
return ("CarryGuardSpec: %d passed, %d failed%s"):format(pass, #failures,
	if #failures > 0 then "\n" .. table.concat(failures, "\n") else "")
