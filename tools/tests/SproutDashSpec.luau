--!nocheck
--==============================================================================
-- Steal a Seed :: SproutDashSpec
-- SPROUT DASH, the mill's minigame (2026-10-08, the owner: "let claude terminal
-- build it"). Edit mode:
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SproutDashSpec"))
--
--   1. the rules     a seed's course is its own; a perfect player runs 2,000 m
--                    unhit; three hits end a run
--   2. the replay    the server counts exactly what the client stepped; a hop
--                    in the air, out of order, a half tick, a hop after the end,
--                    past MaxSeconds -- refused; sim time never beats the clock
--   3. the reward    the distance table; BankMax banked, HourMax an hour
--   4. the service   THE REAL SproutDashService, loaded from its Source with its
--                    services stood in: only on the own mill, a start every
--                    StartEvery s, a forged score ignored (its own replay
--                    counts), off the mill counts nothing, the boost saved
--   5. the wiring    the save's fields, the boost's icon, the mill's payout,
--                    the client's controls and what it sends
-- Simulated user ids only.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SproutDash = require(Shared:WaitForChild("SproutDash"))
local BoostIcons = require(Shared:WaitForChild("BoostIcons"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))

local CFG = GameConfig.SproutDash
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
local function sourceOf(root, name)
	local found = root:FindFirstChild(name, true)
	local ok, text = pcall(function()
		return found.Source
	end)
	return if ok and type(text) == "string" then text else ""
end
local function has(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end

-- A player who hops in the middle of every obstacle's clear window.
local function bot(seed, maxTicks)
	local st = SproutDash.new(seed)
	local hops = {}
	while st.tick < maxTicks and not st.over do
		local want = false
		if SproutDash.grounded(st) then
			local v = SproutDash.speedAt(st.tick)
			local here = math.floor(st.x / CFG.Course.Chunk)
			for index = here, here + 2 do
				for _, o in ipairs(SproutDash.chunkOf(st, index).obstacles) do
					local d = (o.x - o.w / 2) - (st.x + CFG.Runner.W / 2)
					if d > 0 and not st.struck[o.id] then
						local a, b = CFG.Gravity / 2, -CFG.Hop
						local disc = b * b - 4 * a * o.h
						local t1 = (-b - math.sqrt(disc)) / (2 * a)
						local t2 = (-b + math.sqrt(disc)) / (2 * a)
						local mid = (v * t1 + v * t2 - (o.w + CFG.Runner.W)) / 2
						if d <= mid + v / CFG.Hz and d >= mid - 2 * v / CFG.Hz then
							want = true
						end
					end
				end
			end
		end
		if want then
			table.insert(hops, st.tick)
		end
		SproutDash.step(st, want)
	end
	return st, hops
end

local ok, err = pcall(function()

--==============================================================================
say("-- 1. the rules --")
local a, b, c = SproutDash.chunk(12345, 7), SproutDash.chunk(12345, 7), SproutDash.chunk(54321, 7)
check(a.obstacles[1].x == b.obstacles[1].x and a.obstacles[1].kind == b.obstacles[1].kind
		and c.obstacles[1].x ~= a.obstacles[1].x, "a seed's course is its own, chunk by chunk")
local nearest = math.huge
for i = 1, 200 do
	local o1, o2 = SproutDash.chunk(99, i).obstacles[1], SproutDash.chunk(99, i + 1).obstacles[1]
	if o1 and o2 then
		nearest = math.min(nearest, o2.x - o1.x)
	end
end
local hopReach = CFG.Top * 2 * CFG.Hop / CFG.Gravity
check(nearest >= 2 * CFG.Course.Edge and nearest > hopReach,
	string.format("two obstacles are never closer than %.0f m (%.1f here), past a hop at top speed (%.1f m)",
		2 * CFG.Course.Edge, nearest, hopReach))
for _, seed in ipairs({ 1, 777, 4000000000 }) do
	local st, hops = bot(seed, 150 * CFG.Hz)
	check(SproutDash.distance(st) >= 2000 and st.hits == 0,
		string.format("seed %d: a perfect player runs %d m in 150 s, unhit", seed, SproutDash.distance(st)), st.hits)
	local r = SproutDash.replay(seed, hops, st.tick)
	check(r.ok and r.distance == SproutDash.distance(st) and r.coins == st.coins and r.hits == st.hits,
		"and the server's replay counts exactly what the client stepped", r.why)
end
local idle = SproutDash.new(99)
while not idle.over and idle.tick < SproutDash.MaxTicks do
	SproutDash.step(idle, false)
end
check(idle.over and idle.hits == 3 and SproutDash.distance(idle) < SproutDash.firstTier(),
	string.format("never hopping: three hits end the run at %d m, short of any boost", SproutDash.distance(idle)))

--==============================================================================
say("-- 2. the replay refuses what could not have happened --")
local st5, hops5 = bot(5, 30 * CFG.Hz)
local good = SproutDash.replay(5, hops5, st5.tick)
check(good.ok, "a real run replays", good.why)
local air = table.clone(hops5)
table.insert(air, 2, air[1] + 5)
check(SproutDash.replay(5, air, st5.tick).why == "AIR_HOP", "a hop in the air: refused")
check(SproutDash.replay(5, { hops5[2], hops5[1] }, st5.tick).why == "MALFORMED", "hops out of order: refused")
check(SproutDash.replay(5, { 1.5 }, 100).why == "MALFORMED" and SproutDash.replay(5, { -1 }, 100).why == "MALFORMED",
	"a half tick or a negative one: refused")
check(SproutDash.replay(5, hops5, SproutDash.MaxTicks + 1).why == "TOO_LONG", "past MaxSeconds: refused")
local deadAt = SproutDash.replay(99, {}, SproutDash.MaxTicks)
check(deadAt.ok and deadAt.over and SproutDash.replay(99, { deadAt.ticks + 5 }, SproutDash.MaxTicks).why == "AFTER_END",
	"a hop after the third hit: refused")
check(SproutDash.replay("5", hops5, st5.tick).why == "MALFORMED" and SproutDash.replay(5, "x", 10).why == "MALFORMED",
	"not numbers, not a list: refused")
check(SproutDash.timely(60 * CFG.Hz, 59) and not SproutDash.timely(60 * CFG.Hz, 60 - CFG.FinishSlack - 1),
	"a run's sim time never beats the wall clock since its start (" .. CFG.FinishSlack .. " s of network)")

--==============================================================================
say("-- 3. the reward --")
check(SproutDash.minutesFor(249) == 0 and SproutDash.minutesFor(250) == 1 and SproutDash.minutesFor(500) == 2
		and SproutDash.minutesFor(1000) == 3 and SproutDash.minutesFor(2000) == 5 and SproutDash.minutesFor(9999) == 5,
	"250 m 1 min, 500 m 2, 1,000 m 3, 2,000 m+ 5")
local now = 2000000
local s1, e1, log1 = SproutDash.grant(5, 0, {}, now)
local s2, e2, log2 = SproutDash.grant(5, e1, log1, now + 10)
local s3, e3, _, cut3 = SproutDash.grant(5, e2, log2, now + 20)
check(s1 == 300 and s2 == 300 and e2 == now + 600 and s3 == 20 and cut3 == "bank" and e3 == now + 620,
	"two 5-min runs bank 10 min; a third only tops the bank back up to 10 (BankMax)", s3)
local s4, _, _, cut4 = SproutDash.grant(5, 0, { { At = now - 100, Seconds = 600 }, { At = now - 50, Seconds = 300 } }, now)
check(s4 == 0 and cut4 == "hour", "15 boost minutes in an hour, then none (HourMax)", cut4)
local s5 = SproutDash.grant(5, 0, { { At = now - 3700, Seconds = 900 } }, now)
check(s5 == 300, "an hour on, the cap is free again", s5)
check(SproutDash.bonusAt(now + 1, now) == 0.25 and SproutDash.bonusAt(now, now) == 0 and SproutDash.bonusAt(nil, now) == 0,
	"+25% training while it runs, nothing after")

--==============================================================================
say("-- 4. THE REAL SproutDashService --")
local fakePlayers = {}
function fakePlayers:GetPlayers()
	return {}
end
fakePlayers.PlayerAdded = { Connect = function()
	return { Disconnect = function() end }
end }
fakePlayers.PlayerRemoving = fakePlayers.PlayerAdded
local profilesOf, onMill, saves = {}, {}, 0
local function makePlayer(name, userId)
	local attrs = {}
	local p = { Name = name, UserId = userId, Parent = fakePlayers }
	function p:GetAttribute(key)
		return attrs[key]
	end
	function p:SetAttribute(key, value)
		attrs[key] = value
	end
	return p
end
local stand = {
	PlayerDataService = {
		IsReady = function(player)
			return profilesOf[player] ~= nil
		end,
		UpdateSprout = function(player, change)
			local p = profilesOf[player]
			return p ~= nil and change(p) == true
		end,
		Save = function()
			saves += 1
			return true
		end,
	},
	TreadmillService = { OnOwnMill = function(player)
		return onMill[player] == true
	end },
}
local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	end
	return game:GetService(name)
end
local chunk, cerr = loadstring(Server:WaitForChild("SproutDashService").Source, "=SproutDashService")
assert(chunk, tostring(cerr))
local parent = {}
function parent:WaitForChild(name)
	local sibling = stand[name]
	assert(sibling ~= nil, "SproutDashService asked for an unexpected sibling " .. name)
	return { __standIn = sibling }
end
local outerRequire = require
setfenv(chunk, setmetatable({
	game = fakeGame,
	script = { Name = "SproutDashService", Parent = parent },
	require = function(target)
		if type(target) == "table" and target.__standIn ~= nil then
			return target.__standIn
		end
		return outerRequire(target)
	end,
}, { __index = getfenv(1) }))
local S = chunk()
S.Init()
local clock, wall = 100, 2000000
local replies = {}
S.Hooks.clock = function()
	return clock
end
S.Hooks.now = function()
	return wall
end
S.Hooks.onOwnMill = function(player)
	return onMill[player] == true
end
S.Hooks.reply = function(player, payload)
	table.insert(replies, { player = player, payload = payload })
end
local function last()
	return replies[#replies] and replies[#replies].payload or {}
end

local p = makePlayer("SpecSprout", 90000000501)
profilesOf[p] = ProfileSchema.Default()
check(S.Begin(p) == false and last().why == "NOT_ON_MILL", "off the mill: no run")
onMill[p] = true
check(S.Begin(p) == true and last().verb == "started" and type(last().seed) == "number" and type(last().id) == "number",
	"riding the own mill: a run, with the server's seed")
local run1 = last()
clock += 1
check(S.Begin(p) == false and last().why == "TOO_SOON", "another within StartEvery s: refused")

-- A real run of the server's seed, finished in time.
clock += CFG.StartEvery
check(S.Begin(p) == true, "after StartEvery s: a new run (the old one is dropped)")
local run2 = last()
local st, hops = bot(run2.seed, 70 * CFG.Hz)
clock += 75
check(S.Finish(p, { id = run1.id, hops = hops, ticks = st.tick }) == false and last().why == "NO_RUN",
	"the dropped run's id counts nothing")
S.Begin(p)
local run3 = last()
st, hops = bot(run3.seed, 70 * CFG.Hz)
clock += 75
local forged = { id = run3.id, hops = hops, ticks = st.tick, distance = 99999, coins = 9999, granted = 999 }
check(S.Finish(p, forged) == true and last().verb == "counted" and last().distance == SproutDash.distance(st)
		and last().distance ~= 99999 and last().coins == st.coins,
	string.format("a finished run is counted by the server's own replay (%d m), a claimed score ignored",
		SproutDash.distance(st)))
local counted = last()
local pr = profilesOf[p]
check(counted.minutes == SproutDash.minutesFor(counted.distance) and counted.granted == counted.minutes * 60
		and pr.SproutBoostEndsAt == wall + counted.granted and #pr.SproutEarned == 1 and saves == 1,
	string.format("it pays %d min of +25%% training, saved with the profile", counted.minutes))
check(pr.SproutBest == counted.distance and pr.SproutBestDay == SproutDash.day(wall) and counted.best == counted.distance,
	"and today's best is kept")

-- Forged hops: refused, nothing paid.
clock += 5
S.Begin(p)
local run4 = last()
local st4, hops4 = bot(run4.seed, 20 * CFG.Hz)
table.insert(hops4, 2, hops4[1] + 3)
clock += 25
local endsBefore = pr.SproutBoostEndsAt
check(S.Finish(p, { id = run4.id, hops = hops4, ticks = st4.tick }) == false and last().why == "AIR_HOP"
		and pr.SproutBoostEndsAt == endsBefore, "forged hops (one in the air): refused, nothing paid")

-- Faster than the clock: refused.
clock += 5
S.Begin(p)
local run5 = last()
local st5b, hops5b = bot(run5.seed, 40 * CFG.Hz)
clock += 10
check(S.Finish(p, { id = run5.id, hops = hops5b, ticks = st5b.tick }) == false and last().why == "TOO_FAST",
	"40 s of run sent 10 s after its start: refused")

-- Off the mill mid-run: the run is broken and counts nothing.
clock += 5
S.Begin(p)
local run6 = last()
S.Break(p, "OFF_MILL")
check(last().verb == "ended" and last().why == "OFF_MILL", "getting off the mill ends the run and says so")
clock += 30
local st6, hops6 = bot(run6.seed, 20 * CFG.Hz)
check(S.Finish(p, { id = run6.id, hops = hops6, ticks = st6.tick }) == false and last().why == "OFF_MILL",
	"and its finish counts nothing")
clock += 5
S.Begin(p)
local run7 = last()
onMill[p] = false
clock += 30
local st7, hops7 = bot(run7.seed, 20 * CFG.Hz)
check(S.Finish(p, { id = run7.id, hops = hops7, ticks = st7.tick }) == false and last().why == "OFF_MILL",
	"a finish sent from off the mill counts nothing")
onMill[p] = true

-- The bank cap through the service.
pr.SproutBoostEndsAt = wall + 590
pr.SproutEarned = {}
clock += 5
S.Begin(p)
local run8 = last()
local st8, hops8 = bot(run8.seed, 140 * CFG.Hz)
clock += 145
S.Finish(p, { id = run8.id, hops = hops8, ticks = st8.tick })
check(last().ok == true and last().minutes == 5 and last().granted == 10 and last().cut == "bank"
		and pr.SproutBoostEndsAt == wall + 600,
	"with 9:50 banked, a 5-min run tops the boost up to 10 min and says so", last().granted)

--==============================================================================
say("-- 5. the wiring --")
local d = ProfileSchema.Default()
local clean = ProfileSchema.Sanitise({ Version = GameConfig.Save.CurrentVersion, SproutBoostEndsAt = -5,
	SproutEarned = { { At = 10, Seconds = 60 }, { At = "x" }, 7 }, SproutBest = 0 / 0 })
check(d.SproutBoostEndsAt == 0 and #d.SproutEarned == 0 and d.SproutBest == 0 and d.SproutBestDay == 0
		and clean.SproutBoostEndsAt == 0 and #clean.SproutEarned == 1 and clean.SproutBest == 0,
	"the save's new fields default to nothing and clean what is malformed")
local entries = BoostIcons.entries({ now = wall, sproutEndsAt = wall + 120 })
local sprout = nil
for _, e in ipairs(entries) do
	if e.id == "sprout" then
		sprout = e
	end
end
check(sprout ~= nil and sprout.source == "training" and sprout.endsAt == wall + 120
		and table.find(GameConfig.BoostIcons.Order, "sprout") ~= nil and GameConfig.BoostIcons.Tints.sprout ~= nil,
	"its boost shows among the boost icons, with the boosted shoe and its time left")
check(#BoostIcons.entries({ now = wall, sproutEndsAt = wall - 1 }) == 0, "and is gone when it runs out")
local mill = sourceOf(Server, "TreadmillService")
check(has(mill, "SproutDash.bonusAt(sprout and (sprout :: any).SproutBoostEndsAt, os.time())")
		and has(mill, "local paid = rate * training * discoFactor * dt")
		and has(mill, "return mounted[player] ~= nil and discoSpot[player] == nil"),
	"the mill's payout adds the boost to the chest's; OnOwnMill is mounted and not on the Disco Mill")
local ui = sourceOf(StarterPlayer, "SproutDashUI")
-- Not through the PlayerModule: PlayerScripts have none in this engine (it is
-- under StarterPlayer), and waiting for one there never opened the screen.
check(has(ui, "humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)")
		and has(ui, "was.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, was.jump)")
		and has(ui, "(GuiService :: any).TouchControlsEnabled = false")
		and has(ui, "(GuiService :: any).TouchControlsEnabled = was.touch")
		and not has(ui, 'WaitForChild("PlayerModule")')
		and has(ui, "Enum.KeyCode.Space, Enum.KeyCode.ButtonA")
		and has(ui, "return Enum.ContextActionResult.Sink"),
	"while open the humanoid cannot jump and the touch controls hide, both put back as they were; Space and A hop")
check(has(ui, "hitArea.Selectable = false") and has(ui, "GuiService.SelectedObject = nil")
		and has(sourceOf(StarterPlayer, "PadFocus"), "SeedSproutDash = true"),
	"a pad's A reaches the hop: nothing in the game is ever selected, and PadFocus leaves it alone")
check(has(ui, "UIKit.coverRail(playerGui, PANEL_NAME, open and p.covers)") and has(ui, "gui.DisplayOrder = 32")
		and has(ui, "\trelayout()\n\tmodal.setOpen(want)"),
	"laid out afresh on every open, between the rails or over them like the Shop")
local art = GameConfig.SproutDash.Art
local rectsOk = true
for _, name in ipairs({ "rock", "weed", "log", "pot", "heart", "heartEmpty", "dust", "spark" }) do
	local r = (art.Props :: any)[name]
	if typeof(r) ~= "Rect" or r.Min.X < 0 or r.Min.Y < 0 or r.Max.X > 1024 or r.Max.Y > 512 or r.Width <= 0 then
		rectsOk = false
	end
end
check(art.Runner.Image == "rbxassetid://134371957887780" and art.Props.Image == "rbxassetid://87208780933422"
		and art.Ground.Image == "rbxassetid://107251527164014" and art.Backdrop.Image == "rbxassetid://122111644752248"
		and rectsOk and art.Runner.Baseline == 32 and art.Runner.HopBaseline == 72,
	"the owner's four uploads, every prop a rect inside its 1024 x 512 sheet, feet measured on the runner")
check(has(ui, 'send("finish", { id = run.id, hops = run.hops, ticks = state.tick })')
		and has(ui, "string.format(WORDS.Distance, tostring(payload.distance))"),
	"the client sends only its hops and where it stopped, and shows the server's count")
check(has(ui, 'RunService:IsStudio() and player:GetAttribute("SproutDashAutoplay") == true'),
	"its self-hopping test aid runs only in Studio")

-- THE GAME'S OWN MUSIC: a slot for a bed of its own while THIS player has the
-- screen open, on Music.client's one Sound. Empty: the owner's 111742643280141
-- is Pod Rush's ("just pod rush", 2026-10-09), so Sprout Dash keeps the bed.
local music = ""
for _, s in ipairs(StarterPlayer:GetDescendants()) do
	if s.Name == "Music" and s:IsA("LocalScript") then
		music = s.Source
	end
end
local sproutAt = music:find("if #sproutTracks > 0 and sproutOk ~= false and sproutOpen() then", 1, true)
local discoAt = music:find("if #discoTracks > 0 and discoOk ~= false and discoPlaying() then", 1, true)
local _, soundsMade = music:gsub("Instance%.new%(\"Sound\"%)", "")
check(CFG.Music.Id == "" and GameConfig.Music.PodRushTrack == "rbxassetid://111742643280141"
		and CFG.Music.Volume == 0.32 and CFG.Music.Volume == GameConfig.Music.Volume
		and type(CFG.Music.FadeSeconds) == "number" and CFG.Music.FadeSeconds > 0,
	"the slot is empty (the owner's track is Pod Rush's), at the beds' own level (0.32) when it is filled")
check(sproutAt ~= nil and discoAt ~= nil and sproutAt < discoAt and soundsMade == 2
		and has(music, "return localPlayer ~= nil and localPlayer:GetAttribute(SPROUT.Attributes.Open) == true")
		and has(music, "localPlayer:GetAttributeChangedSignal(SPROUT.Attributes.Open):Connect(function()")
		and has(music, "fadeSound(levelFor(want), half)") and has(music, "sproutOk = loaded")
		and has(music, "then tonumber(SPROUT_MUSIC.FadeSeconds) or 1.5"),
	"Music.client: first in the order while THIS player's screen is open, crossfaded in and back on the one Sound, "
		.. "skipped if it cannot load")
check(has(ui, "player:SetAttribute(CFG.Attributes.Open, true)") and has(ui, "player:SetAttribute(CFG.Attributes.Open, nil)"),
	"SproutDashUI says when its screen opens and closes (client-local)")

end)
if not ok then
	fail += 1
	say("  ERROR " .. tostring(err))
end
say(string.format("\nSproutDashSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
