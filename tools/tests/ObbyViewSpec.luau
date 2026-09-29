--!nocheck
--==============================================================================
-- Steal a Seed :: ObbyViewSpec
--
-- What a runner SEES on the Floating Garden (2026-09-29), held without a Play
-- session:
--
--   * every place the course puts a body faces the obstacle that comes next,
--     and ObbyView's landings and facings are ObbyService's own arithmetic;
--   * the camera ObbyView asks for stands behind the body, looks the way the
--     body faces, and keeps the player's zoom and (inside a band) their pitch;
--   * the one-placement state machine: turned once per placement and never
--     otherwise -- not while waiting, not after a timeout, not on a camera that
--     is somebody else's, not twice for one fall -- taken on a camera that
--     follows, only written on one that does not, and a write that did not
--     hold taken once;
--   * no ribbon behind a runner: the one question SpeedFX and TrailFX ask, and
--     that neither of them writes anything a player owns;
--   * the wiring of ObbyCamera, ObbyButtonUI, SpeedFX and TrailFX, read from
--     their source.
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("ObbyViewSpec"))
--
-- WHAT IT CANNOT DO is watch the engine's camera: that the camera turns the
-- wrong way after a fall on a phone, and that taking it for two frames turns it
-- back for good, were measured in Play (KB/HANDOFF.md, the mobile pass).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local ObbyView = require(Shared:WaitForChild("ObbyView"))

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function v3(v)
	return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function degreesBetween(a, b)
	return math.deg(math.acos(math.clamp(flat(a).Unit:Dot(flat(b).Unit), -1, 1)))
end
local function count(text, needle)
	local n, at = 0, 1
	while true do
		local found = string.find(text, needle, at, true)
		if not found then
			return n
		end
		n += 1
		at = found + #needle
	end
end
-- Source with its comments taken out, so a rule written down is not mistaken
-- for a rule in force.
local function code(src)
	local lines = {}
	for _, line in ipairs(string.split(src, "\n")) do
		local at = string.find(line, "--", 1, true)
		table.insert(lines, if at then string.sub(line, 1, at - 1) else line)
	end
	return table.concat(lines, "\n")
end
local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local function sourceOf(name)
	local s = scripts and scripts:FindFirstChild(name)
	return s and s.Source or ""
end

local ok, err = pcall(function()

--==============================================================================
-- 1. EVERY PLACE THE COURSE PUTS A BODY FACES WHAT COMES NEXT
--==============================================================================
say("-- the respawns --")
local KEYS = { "start", "cp1", "cp2", "finished" }
local named = 0
for key in pairs(ObbyData.Respawns) do
	named += 1
	check(table.find(KEYS, key) ~= nil, "respawn '" .. tostring(key) .. "' is one this spec holds to its next obstacle")
end
check(named == #KEYS, "the course has the four respawns: start, two checkpoints and the summit", named)

for _, key in ipairs(KEYS) do
	local landing, forward, nextAt = ObbyView.landing(key), ObbyView.forward(key), ObbyView.nextObstacle(key)
	check(landing ~= nil and forward ~= nil and nextAt ~= nil, key .. ": a landing, a facing and a next obstacle")
	if landing and forward and nextAt then
		local spot = ObbyData.Respawns[key]
		check((landing - (ObbyData.world(spot.at) + Vector3.new(0, 3.5, 0))).Magnitude < 1e-4,
			key .. ": the landing is the respawn's spot, 3.5 over its floor", v3(landing))
		check(math.abs(forward.Magnitude - 1) < 1e-4 and math.abs(forward.Y) < 1e-4,
			key .. ": the facing is level and one stud long", v3(forward))
		local toNext = nextAt - landing
		local off = degreesBetween(forward, toNext)
		check(flat(toNext).Magnitude > 4 and off <= 12,
			string.format("%s: the body faces its next obstacle (%.1f studs away, %.1f degrees off)", key,
				flat(toNext).Magnitude, off), v3(nextAt))
		-- Never facing back down the course: the owner's report was exactly that.
		check(forward:Dot(flat(toNext).Unit) > 0.9, key .. ": and never back the way it came")
	end
end
-- The stages' own checkpoint rows and the respawns agree.
for _, stage in ipairs(ObbyData.Stages) do
	local cp = stage.checkpoint
	if cp then
		local spot = ObbyData.Respawns[cp.id]
		check(spot ~= nil and spot.facing == cp.facing and (spot.at - cp.at).Magnitude < 1e-4,
			stage.id .. ": its checkpoint row and the respawn '" .. cp.id .. "' are one place, one facing")
	end
end
check(ObbyView.landing("nowhere") == nil and ObbyView.forward("nowhere") == nil
		and ObbyView.nextObstacle("nowhere") == nil, "a respawn nobody named has no landing and no facing")

-- The arch: six studs in front of it, facing it and the islands beyond.
do
	local at, forward = ObbyView.entrance()
	local E = ObbyData.Entrance
	check((at - Vector3.new(240, 3.5, -24)).Magnitude < 1e-3, "the OBBY button's landing is (240, 3.5, -24)", v3(at))
	check(degreesBetween(forward, E.At - at) < 1 and degreesBetween(forward, ObbyData.Origin - at) < 12,
		"and it faces the arch, with the first island beyond it", v3(forward))
end

-- ObbyService's own arithmetic, read from its source.
do
	local server = ServerScriptService:FindFirstChild("SeedGameServer")
	local service = server and server:FindFirstChild("ObbyService")
	local src = service and service.Source or ""
	check(src:find("ObbyData.world(spot.at) + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, math.rad(spot.facing), 0)", 1, true) ~= nil
			and ObbyView.RootRise == 3.5,
		"ObbyService puts a body 3.5 over the respawn, turned to its facing: the numbers ObbyView uses")
	check(src:find("CFrame.Angles(0, math.rad(E.FacingDegrees), 0) * CFrame.new(0, 3.5, 6)", 1, true) ~= nil
			and ObbyView.EntranceBack == 6,
		"and stands a player six studs in front of the arch, facing it")
	check(src:find("carryTo(player, respawnFrame(run.respawn))", 1, true) ~= nil
			and src:find('carryTo(player, respawnFrame("start"))', 1, true) ~= nil
			and src:find("put(player, OA.Falls, run.falls)", 1, true) ~= nil
			and src:find('put(player, OA.Checkpoint, "start")', 1, true) ~= nil,
		"a fall raises ObbyFalls and a start names the 'start' respawn before the body is carried: what ObbyCamera waits on")
	-- A falling body is never mistaken for one that has been put down.
	local fallDepth = ObbyView.RootRise - ObbyData.KillBelow
	check(fallDepth > ObbyView.ArriveStuds * 2,
		"a fall is called far under the landing, so a falling body never counts as arrived", fallDepth)
end

--==============================================================================
-- 2. THE CAMERA: BEHIND THE BODY, LOOKING WHERE IT FACES
--==============================================================================
say("-- the camera --")
for _, key in ipairs(KEYS) do
	local landing, forward = ObbyView.landing(key), ObbyView.forward(key)
	for _, zoom in ipairs({ 0.5, 12.5, 40 }) do
		-- The camera as the fall left it: looking back down the course, and down.
		local wrongWay = (-forward + Vector3.new(0, -0.27, 0)).Unit
		local cf = ObbyView.cameraAt(landing, forward, zoom, wrongWay)
		local focus = landing + Vector3.new(0, ObbyView.FocusRise, 0)
		local apart = (cf.Position - focus).Magnitude
		check(degreesBetween(cf.LookVector, forward) < 0.01 and math.abs(apart - zoom) < 1e-3
				and (cf.Position - landing):Dot(forward) < 0
				and (focus - cf.Position).Unit:Dot(cf.LookVector) > 0.9999,
			string.format("%s at zoom %.1f: behind the body, looking the way it faces, at the player's zoom", key, zoom),
			string.format("look %s, %.2f from the focus", v3(cf.LookVector), apart))
	end
end
do
	local east = Vector3.xAxis
	local function pitchFor(look)
		local cf = ObbyView.cameraAt(Vector3.zero, east, 12.5, look)
		return math.deg(math.asin(cf.LookVector.Y))
	end
	local function lookAt(pitch)
		local r = math.rad(pitch)
		return Vector3.new(-math.cos(r), math.sin(r), 0)
	end
	check(math.abs(pitchFor(lookAt(-22)) - -22) < 0.01, "a pitch inside the band is the player's own, kept", pitchFor(lookAt(-22)))
	check(math.abs(pitchFor(lookAt(-75)) - ObbyView.PitchLow) < 0.01,
		"looking straight down the fall is brought up to the band's steep end", pitchFor(lookAt(-75)))
	check(math.abs(pitchFor(lookAt(30)) - ObbyView.PitchHigh) < 0.01,
		"looking at the sky is brought down to the band's level end", pitchFor(lookAt(30)))
	check(math.abs(pitchFor(nil) - ObbyView.PitchDefault) < 0.01
			and math.abs(pitchFor(Vector3.zero) - ObbyView.PitchDefault) < 0.01
			and math.abs(pitchFor(Vector3.new(0 / 0, 0, 0)) - ObbyView.PitchDefault) < 0.01,
		"no look, an empty one or a broken one gets the default pitch")
	check(ObbyView.PitchLow < ObbyView.PitchDefault and ObbyView.PitchDefault < ObbyView.PitchHigh
			and ObbyView.PitchHigh < 0, "the band looks down, and the default is inside it")
	local broken = ObbyView.cameraAt(Vector3.zero, Vector3.zero, 0 / 0, nil)
	check(broken.Position == broken.Position and (broken.Position - Vector3.new(0, ObbyView.FocusRise, 0)).Magnitude > 0.4,
		"a facing of nothing and a zoom of nothing still give a camera", v3(broken.Position))
	check(ObbyView.yawBetween(east, -east) > 179 and ObbyView.yawBetween(east, Vector3.new(1, -0.5, 0)) < 0.01
			and math.abs(ObbyView.yawBetween(east, Vector3.zAxis) - 90) < 0.01,
		"yawBetween measures the turn across the ground, whatever the pitch")
end

-- Which cameras turn by themselves.
do
	local F = ObbyView.follows
	check(F(true, "UserChoice", "Default", "UserChoice", "Default") == true,
		"a phone left at its defaults follows: the owner's case")
	check(F(true, "UserChoice", "Follow", "UserChoice", "Default") == true
			and F(true, "UserChoice", "Classic", "UserChoice", "Follow") == false,
		"a phone set to Follow follows, one set to Classic does not -- the computer's setting is not asked")
	check(F(true, "Classic", "Default", "UserChoice", "Default") == false
			and F(true, "Follow", "Classic", "UserChoice", "Default") == true,
		"the developer's touch mode decides when it is not UserChoice")
	check(F(false, "UserChoice", "Default", "UserChoice", "Default") == false
			and F(false, "UserChoice", "Default", "UserChoice", "Classic") == false
			and F(false, "UserChoice", "Default", "UserChoice", "CameraToggle") == false,
		"a desktop or a console left at its defaults does not follow")
	check(F(false, "UserChoice", "Default", "UserChoice", "Follow") == true
			and F(false, "UserChoice", "Default", "Follow", "Classic") == true,
		"a desktop set to Follow does")
end

--==============================================================================
-- 3. ONE PLACEMENT, EVERY BRANCH
--==============================================================================
say("-- one placement --")
local target, forward = ObbyView.landing("cp1"), ObbyView.forward("cp1")
local falling = target + Vector3.new(30, -29.5, 0)
local wrongWay = -forward
local function frames(watch, now, bodyAt, free, follows, look, n)
	local answers = {}
	for i = 1, n do
		local goal, take = ObbyView.step(watch, now + i * 0.016, bodyAt, free, follows, 12.5, look)
		table.insert(answers, { goal = goal, take = take })
	end
	return answers
end

do
	local watch = ObbyView.new()
	check(not ObbyView.active(watch), "a new watch is idle")
	local a = frames(watch, 0, target, true, true, wrongWay, 3)
	check(a[1].goal == nil and a[3].goal == nil and watch.turns == 0 and not ObbyView.active(watch),
		"idle, it turns nothing -- even with the body standing on a landing")
end

do
	-- A fall on a phone: waiting while the body is still falling, turned the
	-- frame it lands, held HoldFrames frames, then handed back for good.
	local watch = ObbyView.new()
	ObbyView.arm(watch, target, forward, 100)
	check(ObbyView.active(watch) and watch.state == "waiting", "armed, it waits")
	local a = frames(watch, 100, falling, true, true, wrongWay, 5)
	local quiet = true
	for _, f in ipairs(a) do
		quiet = quiet and f.goal == nil and f.take == false
	end
	check(quiet and watch.turns == 0 and watch.state == "waiting", "while the body is still falling it turns nothing")
	local b = frames(watch, 100.1, target + Vector3.new(0.4, -0.5, 0.2), true, true, wrongWay, ObbyView.HoldFrames + 3)
	local held = 0
	for i, f in ipairs(b) do
		if f.goal then
			held += 1
			check(f.take == true and degreesBetween(f.goal.LookVector, forward) < 0.01,
				string.format("frame %d down: the camera is taken and turned to the route", i))
		end
	end
	check(held == ObbyView.HoldFrames and b[1].goal ~= nil and b[ObbyView.HoldFrames + 1].goal == nil,
		string.format("held for %d frame(s) from the frame the body lands, then handed back", ObbyView.HoldFrames), held)
	check(watch.turns == 1 and not ObbyView.active(watch), "one fall, one turn, and then idle", watch.turns)
	local after = frames(watch, 101, target, true, true, wrongWay, 20)
	local touched = false
	for _, f in ipairs(after) do
		touched = touched or f.goal ~= nil
	end
	check(not touched and watch.turns == 1,
		"after that the camera is the player's: nothing more, however they turn it and wherever they stand")
end

do
	-- Repeated falls: each its own single turn.
	local watch = ObbyView.new()
	for n = 1, 4 do
		ObbyView.arm(watch, target, forward, n * 10)
		frames(watch, n * 10, falling, true, true, wrongWay, 3)
		frames(watch, n * 10 + 0.2, target, true, true, wrongWay, ObbyView.HoldFrames + 2)
	end
	check(watch.turns == 4 and not ObbyView.active(watch), "four falls are four turns, one each", watch.turns)
end

do
	-- The teleport that never comes.
	local watch = ObbyView.new()
	ObbyView.arm(watch, target, forward, 50)
	frames(watch, 50, falling, true, true, wrongWay, 3)
	local goal = ObbyView.step(watch, 50 + ObbyView.WaitSeconds + 0.1, target, true, true, 12.5, wrongWay)
	check(goal == nil and watch.turns == 0 and not ObbyView.active(watch),
		"a placement that does not come within WaitSeconds is given up, even if the body wanders there later")
	ObbyView.arm(watch, target, forward, 60, ObbyView.EntranceWaitSeconds)
	check(watch.deadline == 60 + ObbyView.EntranceWaitSeconds and ObbyView.EntranceWaitSeconds < ObbyView.WaitSeconds,
		"the OBBY button's press is waited on for less: the server may have refused it")
end

do
	-- No body: a death on the way.
	local watch = ObbyView.new()
	ObbyView.arm(watch, target, forward, 0)
	local goal = ObbyView.step(watch, 0.1, nil, true, true, 12.5, wrongWay)
	check(goal == nil and not ObbyView.active(watch) and watch.turns == 0, "with no living body the placement is dropped")
	-- And a body lost in the middle of a hold hands the camera back.
	ObbyView.arm(watch, target, forward, 1)
	local first = ObbyView.step(watch, 1.1, target, true, true, 12.5, wrongWay)
	local second = ObbyView.step(watch, 1.2, nil, true, true, 12.5, wrongWay)
	check(first ~= nil and second == nil and not ObbyView.active(watch), "and a body lost mid-hold ends the hold at once")
end

do
	-- Somebody else's camera.
	local watch = ObbyView.new()
	ObbyView.arm(watch, target, forward, 0)
	local goal = ObbyView.step(watch, 0.1, target, false, true, 12.5, wrongWay)
	local later = ObbyView.step(watch, 0.2, target, true, true, 12.5, wrongWay)
	check(goal == nil and later == nil and watch.turns == 0 and not ObbyView.active(watch),
		"a camera that is not the engine's to move when the body lands is left alone, and not turned late")
end

do
	-- A camera that does not follow: written, never taken, and believed.
	local watch = ObbyView.new()
	ObbyView.arm(watch, target, forward, 0)
	local a = frames(watch, 0, target, true, false, wrongWay, ObbyView.HoldFrames)
	local written = true
	for _, f in ipairs(a) do
		written = written and f.goal ~= nil and f.take == false
	end
	check(written, "on a camera that does not follow the CFrame is written and the camera is never taken")
	local gap = ObbyView.step(watch, 1, target, true, false, 12.5, forward)
	check(gap == nil and watch.state == "checking", "then one frame is left to the engine")
	local verdict, take = ObbyView.step(watch, 1.1, target, true, false, 12.5, forward)
	check(verdict == nil and take == false and not ObbyView.active(watch) and watch.turns == 1,
		"the write held -- the camera looks where it was pointed -- so that is the end of it", watch.turns)
end

do
	-- A write that did not hold: taken, once.
	local watch = ObbyView.new()
	ObbyView.arm(watch, target, forward, 0)
	frames(watch, 0, target, true, false, wrongWay, ObbyView.HoldFrames)
	ObbyView.step(watch, 1, target, true, false, 12.5, wrongWay)
	local b = frames(watch, 1.1, target, true, false, wrongWay, ObbyView.HoldFrames + 2)
	local taken = 0
	for _, f in ipairs(b) do
		if f.goal and f.take then
			taken += 1
		end
	end
	check(taken == ObbyView.HoldFrames and watch.turns == 2 and not ObbyView.active(watch),
		"a write the camera undid is followed by one take, and only one", string.format("%d frames, %d turns", taken, watch.turns))
	local after = frames(watch, 3, target, true, false, wrongWay, 10)
	local touched = false
	for _, f in ipairs(after) do
		touched = touched or f.goal ~= nil
	end
	check(not touched and watch.turns == 2, "whatever the camera does after that, it is not turned again")
end

do
	-- A second placement called during a hold.
	local watch = ObbyView.new()
	local other, otherForward = ObbyView.landing("cp2"), ObbyView.forward("cp2")
	ObbyView.arm(watch, target, forward, 0)
	local first = ObbyView.step(watch, 0.1, target, true, true, 12.5, wrongWay)
	ObbyView.arm(watch, other, otherForward, 0.12)
	local between = ObbyView.step(watch, 0.13, target, true, true, 12.5, wrongWay)
	local landed, take = ObbyView.step(watch, 0.5, other, true, true, 12.5, wrongWay)
	check(first ~= nil and between == nil and landed ~= nil and take == true
			and (landed.Position - other).Magnitude < 20,
		"a new placement called mid-hold hands the camera back and waits for its own landing")
end

do
	-- PUT DOWN, THIS FRAME: read off the body itself.
	local seen = true
	for _, key in ipairs(KEYS) do
		local at = ObbyView.landing(key)
		seen = seen and ObbyView.placed(at + Vector3.new(30, -29.5, 4), at + Vector3.new(0.3, -0.4, 0.1)) == key
	end
	check(seen, "a body carried onto a landing from a fall is seen there, on every respawn")
	check(ObbyView.placed(nil, target) == nil, "with no frame before, nothing is called a placement")
	check(ObbyView.placed(target + Vector3.new(7, 1, 0), target) == nil
			and ObbyView.JumpStuds > 100 / 15,
		"a body walking or thrown onto a landing is not one: a spring's 100 studs a second is 7 in a frame at 15 fps",
		ObbyView.JumpStuds)
	check(ObbyView.placed(target, target + Vector3.new(30, -29.5, 0)) == nil
			and ObbyView.placed(target + Vector3.new(40, 0, 0), target + Vector3.new(0, 9, 0)) == nil,
		"and a body carried somewhere that is not a landing is not one either")

	-- A fall's count arriving with the body, or after it, is not answered twice.
	local watch = ObbyView.new()
	ObbyView.arm(watch, target, forward, 10, nil, true)
	frames(watch, 10, target, true, true, wrongWay, ObbyView.HoldFrames + 2)
	check(watch.turns == 1 and not ObbyView.active(watch), "seen landing, the camera is turned")
	ObbyView.arm(watch, target, forward, 10.2)
	local again = frames(watch, 10.2, target, true, true, wrongWay, 4)
	local touched = false
	for _, f in ipairs(again) do
		touched = touched or f.goal ~= nil
	end
	check(not touched and watch.turns == 1 and not ObbyView.active(watch),
		"and the fall's own count, arriving a moment later, turns nothing: one fall, one turn")
	-- While the hold is still on, too.
	local mid = ObbyView.new()
	ObbyView.arm(mid, target, forward, 20, nil, true)
	local first = ObbyView.step(mid, 20.01, target, true, true, 12.5, wrongWay)
	ObbyView.arm(mid, target, forward, 20.02)
	local rest = frames(mid, 20.02, target, true, true, wrongWay, ObbyView.HoldFrames + 2)
	local more = 0
	for _, f in ipairs(rest) do
		if f.goal then
			more += 1
		end
	end
	check(first ~= nil and more == ObbyView.HoldFrames - 1 and mid.turns == 1,
		"arriving during the hold, it neither restarts the hold nor counts as another turn",
		string.format("%d more frame(s), %d turn(s)", more, mid.turns))
	-- The next fall is answered: it is seen, and it is a second away at the least.
	ObbyView.arm(watch, target, forward, 10.4, nil, true)
	frames(watch, 10.4, target, true, true, wrongWay, ObbyView.HoldFrames + 2)
	check(watch.turns == 2, "a body SEEN landing again is always answered, however soon", watch.turns)
	ObbyView.arm(watch, target, forward, 10.4 + ObbyView.SameLandingSeconds + 0.1)
	check(ObbyView.active(watch), "and what is only said is believed again once the last turn is a second old")
	ObbyView.stop(watch)
	local elsewhere = ObbyView.landing("cp2")
	ObbyView.arm(watch, target, forward, 30, nil, true)
	frames(watch, 30, target, true, true, wrongWay, ObbyView.HoldFrames + 2)
	ObbyView.arm(watch, elsewhere, ObbyView.forward("cp2"), 30.1)
	check(ObbyView.active(watch) and watch.target == elsewhere, "or at once, for a different landing")
end

do
	local watch = ObbyView.new()
	ObbyView.arm(watch, nil, forward, 0)
	ObbyView.arm(watch, target, nil, 0)
	check(not ObbyView.active(watch), "a placement with no landing or no facing arms nothing")
	ObbyView.arm(watch, target, forward, 0)
	ObbyView.stop(watch)
	check(not ObbyView.active(watch) and ObbyView.step(watch, 0.1, target, true, true, 12.5, wrongWay) == nil,
		"stopped, it is idle: leaving the course drops whatever was expected there")
end

--==============================================================================
-- 4. NO RIBBON BEHIND A RUNNER
--==============================================================================
say("-- no trail on the course --")
local function someone(attributes)
	return {
		GetAttribute = function(_, name)
			return attributes[name]
		end,
	}
end
local COURSE = ObbyData.Attributes.Course
check(ObbyData.onCourse(someone({ [COURSE] = true })) == true, "a player whose ObbyCourse is true is on the course")
check(ObbyData.onCourse(someone({})) == false and ObbyData.onCourse(someone({ [COURSE] = false })) == false
		and ObbyData.onCourse(someone({ [COURSE] = "true" })) == false and ObbyData.onCourse(someone({ [COURSE] = 1 })) == false
		and ObbyData.onCourse(nil) == false,
	"nobody else is: not set, false, a word, a number, and nobody at all")
check(ObbyData.onCourse(someone({ [COURSE] = true, [ObbyData.Attributes.Stage] = "finished",
		[ObbyData.Attributes.EndedAt] = 1 })) == true,
	"a finished runner waiting on the summit is still on the course")
check(ObbyData.onCourse(someone({ [ObbyData.Attributes.Stage] = "sunpetal", [ObbyData.Attributes.Falls] = 3 })) == false,
	"and once ObbyCourse has gone, nothing else keeps a player there")

for _, row in ipairs({
	{ name = "SpeedFX", want = "local want = tier ~= nil and not onCourse and not teleported and inRange",
		clears = { "entry.trailMain:Clear()", "entry.trailCore:Clear()", "entry.particles:Clear()" } },
	{ name = "TrailFX", want = "local want = near and not onCourse and not teleported and running(entry)",
		clears = { "entry.ribbon:Clear()", "entry.petals:Clear()" } },
}) do
	local src = code(sourceOf(row.name))
	check(src ~= "" and count(src, "local onCourse = ObbyData.onCourse(who)") == 1 and src:find(row.want, 1, true) ~= nil,
		row.name .. " asks ObbyData.onCourse of the player it is drawing, every frame, and draws nothing for a runner")
	local cleared = true
	for _, line in ipairs(row.clears) do
		cleared = cleared and count(src, line) == 1
	end
	check(cleared and src:find("if onCourse ~= entry.onCourse then", 1, true) ~= nil,
		row.name .. " clears what is already in the air, once, on the way in")
	check(not src:find("SetAttribute", 1, true) and not src:find("FireServer", 1, true)
			and not src:find("InvokeServer", 1, true) and not src:find("Cosmetics", 1, true)
			and not src:find("EquippedTrail", 1, true),
		row.name .. " writes no attribute and sends nothing: what a player owns and wears is not touched")
end

--==============================================================================
-- 5. THE WIRING
--==============================================================================
say("-- the wiring --")
do
	local src = code(sourceOf("ObbyCamera"))
	check(src ~= "", "ObbyCamera is in StarterPlayerScripts")
	check(count(src, "RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value - 1, frame)") == 1
			and count(src, "RunService:BindToRenderStep(STEP_AFTER, Enum.RenderPriority.Camera.Value + 1, after)") == 1
			and count(src, "BindToRenderStep(") == 2
			and count(src, "RunService:UnbindFromRenderStep(STEP)") >= 2
			and count(src, "RunService:UnbindFromRenderStep(STEP_AFTER)") >= 2
			and src:find("holding = goal", 1, true) ~= nil and src:find("holding = nil", 1, true) ~= nil
			and not src:find("RenderStepped", 1, true) and not src:find("Heartbeat", 1, true)
			and not src:find("while ", 1, true) and not src:find("task.wait", 1, true),
		"one render step, just before the engine's camera, bound on the course or for a placement: no loop")
	check(src:find("if not ObbyView.active(watch) and not onCourse then\n\t\tunbind()", 1, true) ~= nil
			and src:find("elseif not on then", 1, true) ~= nil,
		"the step unbinds itself the frame the player is off the course with no placement in hand")
	check(src:find("local key = ObbyView.placed(lastAt, at)", 1, true) ~= nil
			and src:find("if at and onCourse then", 1, true) ~= nil
			and src:find("ObbyView.arm(watch, ObbyView.landing(key), ObbyView.forward(key), os.clock(), nil, true)", 1, true) ~= nil
			and src:find("lastAt = nil", 1, true) ~= nil,
		"on the course it watches the body itself, so the frame it lands is the frame the camera is turned")
	check(count(src, "camera.CameraType = Enum.CameraType.Scriptable") == 1
			and src:find("if take and not held then", 1, true) ~= nil
			and count(src, "camera.CameraType = Enum.CameraType.Custom") == 1
			and src:find("elseif held then\n\t\thandBack()", 1, true) ~= nil,
		"the camera is taken only when ObbyView says so, and handed back the first frame it is not wanted")
	check(src:find("VRService.VREnabled or camera.CameraType ~= Enum.CameraType.Custom", 1, true) ~= nil
			and src:find("camera.CameraSubject == humanoid", 1, true) ~= nil,
		"never a headset's camera, a camera something else has taken, or one that is not on this player's body")
	check(src:find("GetAttributeChangedSignal(OA.Falls)", 1, true) ~= nil
			and src:find("if falls > lastFalls and ObbyData.onCourse(player) then", 1, true) ~= nil
			and src:find("GetAttributeChangedSignal(OA.Checkpoint)", 1, true) ~= nil
			and src:find("GetAttributeChangedSignal(OA.Course)", 1, true) ~= nil
			and src:find("GetAttributeChangedSignal(ObbyData.LocalAttributes.EntranceAsked)", 1, true) ~= nil,
		"it waits on a fall, a start or replay, and this client's own OBBY press")
	check(src:find("player.CharacterRemoving:Connect(", 1, true) ~= nil
			and src:find("script.Destroying:Connect(", 1, true) ~= nil
			and count(src, "handBack()") >= 3,
		"a body going or the script going hands the camera back, and a re-run hands back what the last copy took")
	check(not src:find("FireServer", 1, true) and not src:find("InvokeServer", 1, true)
			and count(src, "SetAttribute(") == 2 and count(src, "camera:SetAttribute(HELD") == 2,
		"it sends nothing to the server, and the only thing it marks is the camera while it holds it")
end
do
	local src = code(sourceOf("ObbyButtonUI"))
	check(count(src, "FireServer(") == 1
			and count(src, "player:SetAttribute(ObbyData.LocalAttributes.EntranceAsked, now)") == 1
			and count(src, "SetAttribute(") == 1,
		"the OBBY button still sends its one verb, and notes the press for this client's camera")
	check(ObbyData.LocalAttributes.EntranceAsked ~= nil and ObbyData.Attributes.EntranceAsked == nil,
		"that note is a client's own, kept apart from what the server publishes")
end

end)

if not ok then
	fail += 1
	say("  FAIL  THREW: " .. tostring(err))
end
return string.format("ObbyViewSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
