--!nocheck
--==============================================================================
-- Steal a Seed :: NoticeSpec
--
-- The game's short notifications (2026-09-27): the four kinds, the stack and
-- dedupe rule, the sound throttle, the motion's shape, the one-renderer
-- hand-off, the refusal words and their next steps, and the wiring of the two
-- scripts that draw and post them. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("NoticeSpec"))
--
-- Not here: how a notice LOOKS on a screen (Play captures do that), and where it
-- stands (HudLayoutSpec places the toast rect and the notice stack).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Notice = require(Shared:WaitForChild("Notice"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))

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
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	if not found then
		return nil
	end
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok then src else nil
end

local ok, err = pcall(function()

--==============================================================================
-- 1. FOUR KINDS, NONE BY COLOUR ALONE
--==============================================================================
say("-- the kinds --")
local KINDS = { "blocked", "success", "warning", "info" }
local tints = {}
for _, kind in ipairs(KINDS) do
	local style = Notice.Styles[kind]
	check(style ~= nil and typeof(style.tint) == "Color3", kind .. " has a style and a tint")
	if style then
		tints[kind] = style.tint
		local cue = GameConfig.Sfx.Cues[style.sound]
		check(cue ~= nil and type(cue.id) == "string" and cue.id ~= "",
			kind .. "'s cue " .. tostring(style.sound) .. " has a row with an id")
		check(style.seconds >= 1.5 and style.seconds <= 4, kind .. " is up for a readable while", style.seconds)
	end
end
local function far(a, b)
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) > 0.35
end
check(far(tints.blocked, tints.success) and far(tints.blocked, tints.warning) and far(tints.success, tints.info)
		and far(tints.warning, tints.info) and far(tints.blocked, tints.info),
	"four clearly different tints")
check(tints.blocked.R > tints.blocked.G and tints.blocked.R > tints.blocked.B, "blocked is red")
check(tints.success.G > tints.success.R and tints.success.G > tints.success.B, "success is green")
check(tints.warning.R > 0.9 and tints.warning.G > 0.6 and tints.warning.B < 0.4, "warning is amber")
check(tints.info.B >= tints.info.R and tints.info.B > 0.9, "info is pale blue")
check(Notice.Styles.blocked.sound == "NoticeBlocked" and GameConfig.Sfx.Cues.Denied ~= nil
		and GameConfig.Sfx.Cues.Denied.id == "rbxassetid://102715407432501",
	"blocked has its own cue; Denied is untouched for everything else that refuses")
check(not Notice.isKind("error") and not Notice.isKind(nil) and Notice.isKind("info"), "only the four kinds exist")

--==============================================================================
-- 2. KEYS, HOLDS, AND WHAT IS WORTH DRAWING
--==============================================================================
say("\n-- keys and holds --")
local a = { kind = "info", title = "HELLO", detail = "One." }
check(Notice.keyOf(a) == "info|HELLO|One.", "an identical message is one key", Notice.keyOf(a))
check(Notice.keyOf({ kind = "info", title = "HELLO", detail = "Two.", key = "k" }) == "k", "an explicit key wins")
local short = Notice.holdFor({ kind = "blocked", title = "X", detail = "Short." })
local long = Notice.holdFor({ kind = "blocked", title = "X", detail = string.rep("word ", 20) })
check(short == Notice.Styles.blocked.seconds, "a short detail keeps the kind's time", short)
check(long > short and long <= Notice.MaxSeconds, "a long detail gets more reading time, to a ceiling", long)
check(Notice.holdFor({ kind = "info", title = "X", seconds = 3.5 }) == 3.5, "an explicit time is honoured")
check(Notice.holdFor({ kind = "info", title = "X", seconds = 60 }) == Notice.MaxSeconds, "up to the ceiling")
check(Notice.lifeOf(a) == Notice.EnterSeconds + Notice.holdFor(a), "a notice's life is its entrance plus its hold")
check(Notice.valid(a), "a good post is drawn")
check(not Notice.valid({ kind = "loud", title = "X" }), "an unknown kind is not")
check(not Notice.valid({ kind = "info", title = "" }), "nor an empty headline")
check(not Notice.valid({ kind = "info", title = "X", detail = 5 }), "nor a detail that is not words")
check(not Notice.valid({ kind = "info", title = "X", stillTrue = function() return false end }),
	"nor a notice whose situation has already ended")
check(not Notice.valid({ kind = "info", title = "X", stillTrue = function() error("boom") end }),
	"nor one whose check throws")
check(Notice.valid({ kind = "info", title = "X", stillTrue = function() return true end }),
	"a notice whose situation still holds is drawn")

--==============================================================================
-- 3. THE STACK: DEDUPE, ROOM, NOTHING LATE
--==============================================================================
say("\n-- the stack --")
do
	local stack = {}
	local p1 = { kind = "blocked", title = "ONE" }
	local p2 = { kind = "success", title = "TWO" }
	local p3 = { kind = "warning", title = "THREE" }
	local p4 = { kind = "info", title = "FOUR" }
	check(Notice.step(stack, p1, 10, 3) == "show" and #stack == 1, "the first goes up")
	for i = 1, 30 do
		Notice.step(stack, p1, 10 + i * 0.03, 3)
	end
	check(#stack == 1 and stack[1].count == 31, "thirty repeats are one notice, counted", stack[1].count)
	check(Notice.step(stack, p2, 11, 3) == "show" and Notice.step(stack, p3, 11.1, 3) == "show" and #stack == 3,
		"different ones stack")
	-- p1 was refreshed last at 10.9, p2 went up at 11, p3 at 11.1: p1 is due to leave first.
	local verdict, index, evicted = Notice.step(stack, p4, 11.2, 3)
	check(verdict == "show" and #stack == 3 and #evicted == 1 and evicted[1].key == Notice.keyOf(p1),
		"a fourth makes room by taking down the one due to leave first",
		(evicted[1] and evicted[1].key) or "none")
	check(index == #stack and stack[#stack].key == Notice.keyOf(p4), "and goes up at the bottom")
	local small = {}
	for i, p in ipairs({ p1, p2, p3, p4 }) do
		Notice.step(small, p, 20 + i * 0.1, 2)
	end
	check(#small == 2, "a small screen keeps two", #small)
	local gone = { { key = Notice.keyOf(p1), kind = "blocked", bornAt = 0, hideAt = 3, count = 1 } }
	check(Notice.step(gone, p1, 3.01, 3) == "show", "a notice whose time is up is new again")
	check(Notice.remove(gone, Notice.keyOf(p1)) and not Notice.remove(gone, Notice.keyOf(p1)),
		"taking one out works once")
	-- Nothing waits: every post is shown at once or makes room; there is no queue.
	local verdicts = {}
	local s = {}
	for i = 1, 12 do
		local v = Notice.step(s, { kind = KINDS[(i % 4) + 1], title = "N" .. i }, 30 + i * 0.01, 3)
		verdicts[v] = true
	end
	local onlyShow = true
	for v in pairs(verdicts) do
		if v ~= "show" then
			onlyShow = false
		end
	end
	check(onlyShow and #s == 3,
		"twelve different notices in a burst: each shown at once or making room, never queued", #s)
end

--==============================================================================
-- 4. THE SOUND THROTTLE
--==============================================================================
say("\n-- sounds --")
do
	local st = Notice.newSoundState()
	local b = { kind = "blocked", title = "B" }
	local g = { kind = "success", title = "G" }
	check(Notice.soundFor(st, b, 100) == "NoticeBlocked", "the first notice sounds")
	check(Notice.soundFor(st, g, 100 + Notice.SoundGapSeconds / 2) == nil,
		"a second one in the same moment does not: no stacking two sounds")
	check(Notice.soundFor(st, g, 100 + Notice.SoundGapSeconds + 0.01) == "NoticeSuccess",
		"a different kind a moment later does")
	check(Notice.soundFor(st, b, 100 + Notice.SoundGapSeconds * 2 + 0.02) == nil
			and Notice.KindGapSeconds > Notice.SoundGapSeconds * 2 + 0.02,
		"the same kind again that soon does not")
	check(Notice.soundFor(st, b, 100 + Notice.KindGapSeconds + 1) == "NoticeBlocked", "and later it does again")
	check(Notice.soundFor(Notice.newSoundState(), { kind = "success", title = "Q", quiet = true }, 0) == nil,
		"a quiet notice adds no sound to an action that made its own")
end

--==============================================================================
-- 5. THE MOTION'S SHAPE
--==============================================================================
say("\n-- motion --")
do
	local hold = 2.5
	local y0, s0, a0 = Notice.pose(0, hold)
	check(a0 == 1 and y0 == Notice.RisePixels and s0 == Notice.StartScale,
		"it starts invisible, a little low and a little small")
	local mono, peakScale, lastY, lastA = true, 0, math.huge, 2
	for i = 0, 40 do
		local t = Notice.EnterSeconds * i / 40
		local y, sc, al = Notice.pose(t, hold)
		if y > lastY + 1e-9 or al > lastA + 1e-9 then
			mono = false
		end
		lastY, lastA = y, al
		peakScale = math.max(peakScale, sc)
	end
	check(mono, "it rises and fades in without ever going back")
	check(peakScale <= 1 + 1e-9, "the scale settles without overshoot: no bounce", peakScale)
	local y1, s1, a1 = Notice.pose(Notice.EnterSeconds + hold / 2, hold)
	check(y1 == 0 and s1 == 1 and a1 == 0, "through the hold it is fully readable and still")
	local yE, _, aE = Notice.pose(Notice.EnterSeconds + hold + Notice.ExitSeconds, hold)
	check(aE >= 0.999 and yE <= 0 and yE >= -6, "it fades out with a few pixels of upward drift", yE)
	local stillOk = true
	for i = 0, 20 do
		local y, sc = Notice.pose(i * 0.2, hold, true)
		if y ~= 0 or sc ~= 1 then
			stillOk = false
		end
	end
	check(stillOk, "reduced motion keeps the fades and drops the rise and the scale")
	check(Notice.EnterSeconds <= 0.35 and Notice.ExitSeconds <= 0.4 and Notice.NudgeScale <= 1.06,
		"short, gentle numbers: no dramatic entrance, no big bounce")
	check(Notice.TimeScale == 1, "the game runs at real speed (TimeScale is for filming previews only)")
end

--==============================================================================
-- 6. ONE RENDERER, IN ITS OWN SCRIPT
--==============================================================================
say("\n-- the renderer slot --")
do
	local got1, got2 = {}, {}
	Notice.setRenderer(nil)
	Notice.post({ kind = "info", title = "LOST" })
	Notice.setRenderer(function(p)
		table.insert(got1, p)
	end)
	Notice.post({ kind = "info", title = "ONE", stillTrue = function()
		return true
	end })
	Notice.post({ kind = "nope", title = "BAD" })
	task.wait()
	check(#got1 == 1 and got1[1].title == "ONE", "a renderer gets valid posts, and only those", #got1)
	check(#got1 == 1 and type(got1[1].stillTrue) == "function",
		"a post's stillTrue survives the hand-off (only its number crosses the event)")
	Notice.setRenderer(function(p)
		table.insert(got2, p)
	end)
	Notice.post({ kind = "success", title = "TWO" })
	task.wait()
	check(#got1 == 1 and #got2 == 1, "a second renderer replaces the first: never drawn twice", #got1 .. "/" .. #got2)
	Notice.setRenderer(nil)
	Notice.post({ kind = "success", title = "THREE" })
	task.wait()
	check(#got2 == 1, "with no renderer a post is dropped, not kept for later")
end

--==============================================================================
-- 7. THE REFUSAL WORDS: A HEADLINE AND A NEXT STEP THAT WORKS
--==============================================================================
say("\n-- refusal notices --")
do
	local missing, bad = {}, {}
	for code in pairs(ActionRefusal.Text) do
		local line = ActionRefusal.Notices[code]
		if not line then
			table.insert(missing, code)
		else
			if string.upper(line.title) ~= line.title or #line.title > 20 or string.find(line.title, "[^%w %p]") then
				table.insert(bad, code .. " title")
			end
			if line.detail and (#line.detail > 48 or string.sub(line.detail, -1) ~= ".") then
				table.insert(bad, code .. " detail")
			end
		end
	end
	for code in pairs(ActionRefusal.Notices) do
		if ActionRefusal.Text[code] == nil then
			table.insert(missing, code .. " (no sentence)")
		end
	end
	table.sort(missing)
	table.sort(bad)
	check(#missing == 0, "every refusal code has a notice and a sentence", table.concat(missing, ", "))
	check(#bad == 0, "headlines are short, upper case, plain; next steps are one short sentence",
		table.concat(bad, ", "))
	local owner = ActionRefusal.Notices.PLOT_FULL
	check(owner.title == "GARDEN FULL" and owner.detail == "Pick up a plant or upgrade your plot.",
		"the owner's own example, word for word")
	check(ActionRefusal.plotFull(true, true) == "PLOT_FULL", "full, something grown, a level to buy: both steps")
	check(ActionRefusal.plotFull(false, true) == "PLOT_FULL_MAX", "at the top level: pick up only")
	check(ActionRefusal.plotFull(true, false) == "PLOT_FULL_GROWING", "nothing grown yet: upgrade only")
	check(ActionRefusal.plotFull(false, false) == "PLOT_FULL_WAIT", "neither: wait for one to grow")
	check(not string.find(string.lower(ActionRefusal.Notices.PLOT_FULL_MAX.detail), "upgrade")
			and not string.find(string.lower(ActionRefusal.Notices.PLOT_FULL_GROWING.detail), "pick up")
			and not string.find(string.lower(ActionRefusal.Notices.PLOT_FULL_WAIT.detail), "upgrade"),
		"no variant offers a step its situation rules out")
	local post = ActionRefusal.notice("TELEPORT_COOLDOWN")
	check(post ~= nil and post.kind == "blocked" and post.key == "refusal:TELEPORT_COOLDOWN"
			and post.title == "TELEPORT RECHARGING",
		"a code becomes a blocked notice keyed by its code")
	check(ActionRefusal.notice("NOPE") == nil and ActionRefusal.notice(nil) == nil, "an unknown code is nothing")
	for _, code in ipairs({ "TELEPORT_COOLDOWN", "TELEPORT_NO_PLOT", "TELEPORT_BLOCKED" }) do
		check(ActionRefusal.Notices[code].detail == nil, code .. ": nothing to do but wait, so no next step")
	end
end

--==============================================================================
-- 8. THE WIRING: WHO DRAWS, WHO POSTS, WHAT THEY MAY DO
--==============================================================================
say("\n-- wiring --")
do
	local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	local toast = sourceOf(scripts, "ActionToastUI") or ""
	check(toast:find("Notice.setRenderer(show)", 1, true) ~= nil, "ActionToastUI is the one renderer")
	check(toast:find("local post = ActionRefusal.notice(code)", 1, true) ~= nil
			and toast:find("action == ActionRefusal.Action", 1, true) ~= nil,
		"it draws a server refusal from its code")
	check(not toast:find("while true", 1, true) and not toast:find("Heartbeat", 1, true)
			and not toast:find("RenderStepped", 1, true),
		"no loop and no per-frame hook")
	check(not toast:find("SetAttribute(", 1, true) and not toast:find("FireServer(", 1, true),
		"it tells nobody anything back")
	-- One exception since 2026-10-01: the close button of a notice the poster
	-- marked `dismissible` (the like reminder). It is the only button, made only
	-- inside that branch; nothing else takes input or a controller's selection.
	local branch = toast:find("if post.dismissible == true then", 1, true)
	local made = toast:find('Instance.new("TextButton")', 1, true)
	local _, buttons = string.gsub(toast, 'Instance%.new%("TextButton"%)', "")
	local _, selectable = string.gsub(toast, "Selectable = true", "")
	check(not toast:find("ImageButton", 1, true) and not toast:find("Active = true", 1, true)
			and buttons == 1 and selectable == 1 and branch ~= nil and made ~= nil and made > branch
			and toast:find("close.Selectable = true", 1, true) ~= nil,
		"nothing in it can take input or a controller's selection, but a dismissible notice's close button",
		string.format("%d buttons, %d selectable", buttons, selectable))
	check(toast:find("GameConfig.Afterimage.QualityAttribute", 1, true) ~= nil
			and toast:find("ReducedMotionEnabled", 1, true) ~= nil,
		"it honours REDUCED FX and Roblox's reduced motion")
	check(toast:find("SoundKit.has(cue)", 1, true) ~= nil
			and toast:find("Notice.soundFor(sounds, post, now)", 1, true) ~= nil,
		"a missing cue plays nothing; the throttle picks every sound")
	check(toast:find("local now = Notice.now()", 1, true) ~= nil, "the rules run on the renderer's own clock")
	local chest = sourceOf(scripts, "BonusChestUI") or ""
	check(chest:find("Notice.post(", 1, true) ~= nil and not chest:find("showCard", 1, true)
			and not chest:find("SoundKit.play(\"SellAll\")", 1, true),
		"the Bonus Chest answers through the shared notices, with the notice's one sound")
	local place = sourceOf(scripts, "PlantPlace") or ""
	check(place:find("ActionRefusal.plotFull(", 1, true) ~= nil,
		"the controller's full-plot refusal names the same step")
	local server = ServerScriptService:FindFirstChild("SeedGameServer")
	local plant = sourceOf(server, "PlantService") or ""
	check(plant:find("reason = ActionRefusal.plotFull(", 1, true) ~= nil
			and plant:find("if reason == \"PLOT_FULL\" then PlotService.PlotOf(player)", 1, true) ~= nil,
		"the server picks the full-plot step after the same refusal, and only then")
end

--==============================================================================
-- 9. THE CUES: THE OWNER'S FOUR RECORDINGS, EACH ON ITS OWN ROW
--==============================================================================
say("\n-- cues --")
do
	local C = GameConfig.Sfx.Cues
	local WANT = {
		NoticeBlocked = "rbxassetid://129733199607968",
		-- "success new", 2026-09-27; it replaced 100270581576092 on this row only.
		-- The CrazyCozy Games group's copy since 2026-09-28: the first one
		-- (123803156310043) was on the owner's own account.
		NoticeSuccess = "rbxassetid://104123841960377",
		NoticeWarning = "rbxassetid://122434285599993",
		NoticeInfo = "rbxassetid://80357294905654",
	}
	for name, id in pairs(WANT) do
		check(C[name] ~= nil and C[name].id == id, name .. " plays its own upload", C[name] and C[name].id)
		check(C[name] ~= nil and (C[name].group or "UI") == "UI" and C[name].range == nil,
			name .. " is a 2D cue on the UI bus, so SOUND FX sets its level")
		check(C[name] ~= nil and C[name].volume > 0 and C[name].volume <= 2, name .. " has a level in the band")
	end
	local used = {}
	for name, cue in pairs(C) do
		for want, id in pairs(WANT) do
			if cue.id == id and name ~= want then
				table.insert(used, name)
			end
		end
	end
	check(#used == 0, "and no other row plays those uploads", table.concat(used, ", "))
	check(C.NoticeWarning.fadeOut ~= nil and C.NoticeWarning.clip ~= nil
			and C.NoticeWarning.fadeOut < C.NoticeWarning.clip,
		"the warning, still sounding where its render stops, fades out rather than being cut")
	-- The new success chime is 1.28 s and decays to silence by itself: no
	-- window may cut it, and its level lands with the other notices (about
	-- -21 dB from a -13.6 dB file, where the old 0.48 s render needed 1.40).
	local chime = C.NoticeSuccess
	check(chime ~= nil and chime.start == nil and chime.clip == nil and chime.fadeOut == nil,
		"the success chime plays whole: no start offset, no window, no fade")
	check(chime ~= nil and chime.volume >= 0.35 and chime.volume <= 0.5,
		"and at a notice's level, not the old render's 1.40", chime and chime.volume)
end

end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
Notice.setRenderer(nil)

say(string.format("\nNoticeSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
