--==============================================================================
-- FirstHatchSpec (2026-10-16, the owner's fix for the onboarding funnel's step 4:
-- 43% of the players who banked a first pod never hatched it; the plan and the
-- owner's answers: KB/FIRST-HATCH-FIX-PLAN.md)
--
--   1. the numbers and the words: the first bank's 10 s, the card's lines, the
--      owner's sound
--   2. the card's arithmetic (Shared/FirstHatchCard): its pod, its words at each
--      moment, when it stands, where it lands the body
--   3. where it stands: low in the middle, over the hotbar, clear of the whole
--      HUD on the desktop sizes and every listed phone
--   4. the two analytics events: once per player, the cohort only
--   5. the server: the first bank's stamp, the ready moment, the pending flag,
--      the one-tap verb's guards, home first and the hatch after
--   6. the clients: the card, the camera's turn, the guide's hand and words,
--      no Instant Hatch on that pod
-- Edit mode; nothing is left behind.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local FirstMinute = require(Shared:WaitForChild("FirstMinute"))
local FirstHatchCard = require(Shared:WaitForChild("FirstHatchCard"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local TutorialData = require(Shared:WaitForChild("TutorialData"))
local Metrics = require(Server:WaitForChild("Metrics"))

local FIRST = GameConfig.FirstHatch
local WORDS = FIRST.Words
local BAG = GameConfig.HatchInBag

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
		return ""
	end
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
local function count(src, text)
	local n, at = 0, 1
	while true do
		local s, e = string.find(src, text, at, true)
		if not s then
			return n
		end
		n += 1
		at = e + 1
	end
end
-- The text between `from` and the next `to` after it.
local function between(src, from, to)
	local a = string.find(src, from, 1, true)
	if not a then
		return ""
	end
	local b = string.find(src, to, a + #from, true)
	return string.sub(src, a, b or #src)
end

local function body()
	--==========================================================================
	say("1. The numbers and the words")
	--==========================================================================
	check(FirstMinute.FirstHatchSeconds == 10 and FirstMinute.bankWait(60, true) == 10
			and FirstMinute.bankWait(60, false) == 60 and FirstMinute.bankWait(5, true) == 5
			and FirstMinute.bankWait(4500, true) == 10 and FirstMinute.bankWait(4500, false) == 4500,
		"the first pod ever banked is ready in 10 s (a Big's 60 and a Colossal's 4,500 alike), never later than "
			.. "its ladder; every later pod waits the ladder's time")
	check(FirstHatchCard.MaxHeightShare <= 0.4 and FirstHatchCard.MinScale >= 0.5,
		"a phone's card is the smaller one: never over 40% of the screen's height, never under half size")
	check(SeedData.GrowSeconds(FirstMinute.CatchTier) == 60,
		"(the first catch is at least Big, whose rung of the ladder is 60 s: the wait this replaces)")
	check(WORDS.Growing == "YOUR POD IS GROWING\u{2026}" and WORDS.Ready == "YOUR POD IS READY!"
			and WORDS.Hatch == "HATCH!" and WORDS.ReadyIn == "Ready in %s" and WORDS.Pod == "%s %s",
		"the owner's card: YOUR POD IS GROWING… / Ready in 0:07, then YOUR POD IS READY! and HATCH!")
	check(FIRST.Sound == "MistPodReady" and GameConfig.Sfx.Cues.MistPodReady ~= nil
			and type(GameConfig.Sfx.Cues.MistPodReady.id) == "string",
		"its ready sound is the owner's existing upload, the Mist's pod-ready ping")
	check(BAG.FirstHatch == "BagFirstHatch" and FIRST.PendingAttribute == "FirstHatchPending"
			and type(FIRST.AskedAttribute) == "string" and FIRST.AskedAttribute ~= FIRST.PendingAttribute
			and FIRST.HatchDelaySeconds > 0 and FIRST.HatchDelaySeconds < 2,
		"one verb, one server flag, one client-only note, and a moment between the teleport and the hatch")
	local step = nil
	for _, s in ipairs(TutorialData.Steps) do
		if s.Id == "hatch" then
			step = s
		end
	end
	check(step ~= nil and step.Detail == "Tap HATCH when your pod is ready!",
		"the guide's hatch step says the owner's words: Tap HATCH when your pod is ready!", step and step.Detail)

	--==========================================================================
	say("2. The card's arithmetic")
	--==========================================================================
	local pods = {
		{ item = "b", speciesId = "petalpip", tier = 2, hatchAt = 1010 },
		{ item = "a", speciesId = "petalpip", tier = 2, hatchAt = 1010 },
		{ item = "c", speciesId = "petalpip", tier = 3, hatchAt = 1100 },
		{ item = "", speciesId = "petalpip", tier = 2, hatchAt = 900 },
	}
	local picked = FirstHatchCard.pick(pods)
	check(picked ~= nil and picked.item == "a" and FirstHatchCard.pick({}) == nil,
		"its pod: the soonest due in the Bag, ties by item id, a pod with no id never")
	local growing = FirstHatchCard.view(pods[2], 1003, "Big", "Petalpip")
	check(growing.title == WORDS.Growing and growing.pod == "BIG Petalpip" and growing.line == "Ready in 0:07"
			and growing.ready == false and growing.left == 7,
		"7 s to go: YOUR POD IS GROWING…, BIG Petalpip, Ready in 0:07, HATCH not yet", growing.line)
	local almost = FirstHatchCard.view(pods[2], 1009.4, "Big", "Petalpip")
	local ready = FirstHatchCard.view(pods[2], 1010, "Big", "Petalpip")
	check(almost.line == "Ready in 0:01" and almost.ready == false and ready.title == WORDS.Ready
			and ready.line == nil and ready.ready == true,
		"a part second reads 0:01, never 0:00 while time is left; at its time: YOUR POD IS READY!, no countdown")
	check(FirstHatchCard.clock(60) == "1:00" and FirstHatchCard.clock(0) == "0:00",
		"its clock: minutes and seconds")
	check(FirstHatchCard.shown(true, pods[1], false, false) and not FirstHatchCard.shown(false, pods[1], false, false)
			and not FirstHatchCard.shown(true, nil, false, false) and not FirstHatchCard.shown(true, pods[1], true, false)
			and not FirstHatchCard.shown(true, pods[1], false, true),
		"it stands only while a first hatch is pending with a pod for it, nothing over it, its HATCH not yet pressed")
	local spawn = CFrame.new(10, 4, 20) * CFrame.Angles(0, 0.7, 0)
	local landed = FirstHatchCard.landing(spawn)
	local bed = Vector3.new(-6, 0.5, 31)
	local facing = FirstHatchCard.landing(spawn, bed)
	local want = (Vector3.new(bed.X, 4, bed.Z) - spawn.Position).Unit
	local under = FirstHatchCard.landing(spawn, spawn.Position + Vector3.new(0.3, -3, 0.2))
	check((landed.Position - spawn.Position).Magnitude < 1e-6 and (landed.LookVector + spawn.LookVector).Magnitude < 1e-6
			and (facing.Position - spawn.Position).Magnitude < 1e-6 and facing.LookVector:Dot(want) > 0.9999
			and math.abs(facing.LookVector.Y) < 1e-6 and (under.LookVector + spawn.LookVector).Magnitude < 1e-6,
		"its HATCH lands the body on the plot's spawn, level, facing the bed its plant comes up in -- with none, "
			.. "or one under its feet, turned round into the garden, never out of the gate")

	--==========================================================================
	say("3. Where it stands")
	--==========================================================================
	local TOPBAR, BAR_LEFT = 58, 208
	local function screen(w, h, touch)
		return {
			safe = Vector2.new(w, h - TOPBAR),
			touch = touch,
			keyboard = not touch,
			viewport = Vector2.new(w, h),
			topbar = { x = BAR_LEFT, y = 0, w = w - BAR_LEFT, h = TOPBAR },
			insetTop = TOPBAR,
		}
	end
	local cases = {}
	for _, d in ipairs({ { 1920, 1080 }, { 1280, 720 }, { 1046, 739 }, { 942, 739 }, { 1024, 600 } }) do
		table.insert(cases, { tag = string.format("%dx%d desktop", d[1], d[2]), input = screen(d[1], d[2], false) })
	end
	for _, p in ipairs({ { 640, 480 }, { 772, 360 }, { 874, 402 }, { 896, 414 }, { 956, 440 }, { 1000, 609 },
		{ 705, 338 }, { 640, 360 }, { 801, 392 } }) do
		table.insert(cases, { tag = string.format("%dx%d phone", p[1], p[2]), input = screen(p[1], p[2], true) })
	end
	local G = FirstHatchCard.Gap
	local bad, smallest, smallestTag = nil, math.huge, ""
	for _, case in ipairs(cases) do
		local L = HudLayout.solve(case.input)
		local avoid = HudLayout.occupied(L)
		local r, scale = FirstHatchCard.rect(L.safe, avoid)
		local why = nil
		if r.w <= 0 or scale < FirstHatchCard.MinScale - 1e-9 then
			why = "no place"
		elseif r.x < G or r.y < G or r.x + r.w > L.safe.X - G or r.y + r.h > L.safe.Y - G then
			why = "off the safe area"
		elseif math.abs((r.x + r.w / 2) - L.safe.X / 2) > 1 then
			why = "not centred"
		elseif r.y + r.h < L.safe.Y * 0.6 then
			why = "its bottom edge above the lowest 40%"
		elseif r.h > FirstHatchCard.MaxHeightShare * L.safe.Y + 1 then
			why = "taller than its share of the screen"
		else
			for _, a in ipairs(avoid) do
				if r.x < a.x + a.w + G and a.x < r.x + r.w + G and r.y < a.y + a.h + G and a.y < r.y + r.h + G then
					why = string.format("over a HUD rect at %d,%d %dx%d", a.x, a.y, a.w, a.h)
					break
				end
			end
		end
		if not why then
			-- As low as it can stand: 4 px lower is off the screen or over something.
			local lower = { x = r.x, y = r.y + 4, w = r.w, h = r.h }
			local lowerClear = lower.y + lower.h <= L.safe.Y - G
			if lowerClear then
				for _, a in ipairs(avoid) do
					if lower.x < a.x + a.w + G and a.x < lower.x + lower.w + G and lower.y < a.y + a.h + G
						and a.y < lower.y + lower.h + G then
						lowerClear = false
						break
					end
				end
			end
			if lowerClear then
				why = "a lower place was clear"
			end
		end
		if why and not bad then
			bad = case.tag .. ": " .. why
		end
		if scale < smallest then
			smallest, smallestTag = scale, case.tag
		end
	end
	check(bad == nil,
		string.format("on %d screens (5 desktop sizes, 9 phones with their thumbstick and jump) it stands centred, "
			.. "as low as it can over the hotbar (its bottom edge in the lowest 40%%), never taller than %d%% of the "
			.. "screen, inside the safe area and %d px clear of every HUD rect; the smallest, %s, at %.2f", #cases,
			math.round(FirstHatchCard.MaxHeightShare * 100), G, smallestTag, smallest), bad)

	--==========================================================================
	say("4. The two analytics events")
	--==========================================================================
	local sent = {}
	local mock = {
		onboarding = function() end,
		funnel = function() end,
		custom = function(player, name, value, fields)
			table.insert(sent, { player = player, name = name, value = value })
		end,
	}
	Metrics.reset()
	Metrics.useSink(mock)
	Metrics.useClock(function()
		return 1000
	end)
	Metrics.useStaffCheck(function()
		return false
	end)
	Metrics.configure({ Enabled = true, ExcludeStaff = true, StaffValidation = false, PerMinuteBase = 1000,
		PerMinutePerPlayer = 0, ReserveShare = 0.25, CohortSince = 5000, Obby = false })
	Metrics.useHeadcount(function()
		return 0
	end)
	local newbie, veteran = { Name = "Newbie" }, { Name = "Veteran" }
	Metrics.profileReady(newbie, { CreatedAt = 6000 }, true, true)
	Metrics.profileReady(veteran, { CreatedAt = 100 }, false, true)
	Metrics.firstPodReady(newbie)
	Metrics.firstPodReady(newbie)
	Metrics.firstHatchCard(newbie)
	Metrics.firstHatchCard(newbie)
	Metrics.firstPodReady(veteran)
	Metrics.firstHatchCard(veteran)
	local names = {}
	for _, e in ipairs(sent) do
		if e.player == newbie then
			table.insert(names, e.name)
		elseif e.player == veteran then
			table.insert(names, "VETERAN:" .. e.name)
		end
	end
	check(#names == 2 and names[1] == "FirstPodReady" and names[2] == "FirstHatchCardPressed"
			and Metrics.Events.FirstPodReady == "FirstPodReady" and Metrics.Events.FirstHatchCard == "FirstHatchCardPressed",
		"FirstPodReady and FirstHatchCardPressed go out once per player in the new-player cohort, never for a "
			.. "veteran", table.concat(names, ","))
	Metrics.useSink(nil)
	Metrics.configure(nil)
	Metrics.useStaffCheck(nil)
	Metrics.useClock(nil)
	Metrics.useHeadcount(nil)
	Metrics.reset()

	--==========================================================================
	say("5. The server")
	--==========================================================================
	local carry = sourceOf(Server, "CarryService")
	local bankFn = between(carry, "local function bank(player: Player): boolean", "\nend\n")
	local stampAt = string.find(bankFn, "local firstBank = PlayerDataService.TutorialDone(player, \"bank\") == false", 1, true)
	local hatchAtAt = string.find(bankFn,
		"local hatchAt = os.time() + FirstMinute.bankWait(PassService.GrowSeconds(player, species, tier), firstBank)", 1, true)
	local recordAt = string.find(bankFn, "PlayerDataService.RecordTutorial(player, \"bank\")", 1, true)
	local readyAt = string.find(bankFn, "if firstBank then\n\t\ttask.delay(math.max(0, hatchAt - os.time()), function()", 1, true)
	check(stampAt and hatchAtAt and recordAt and readyAt and stampAt < hatchAtAt and hatchAtAt < recordAt
			and recordAt < readyAt,
		"the bank: `bank` read BEFORE it is recorded, the first one's HatchAt from FirstMinute.bankWait over the "
			.. "pass-aware ladder, then the ready moment's one timer")
	check(has(bankFn, "if player.Parent == Players and PlayerDataService.TutorialDone(player, \"hatch\") == false then\n"
			.. "\t\t\t\tMetrics.firstPodReady(player)"),
		"FirstPodReady only for a player still here whose first pod is still unhatched")
	local data = sourceOf(Server, "PlayerDataService")
	local publish = between(data, "function PlayerDataService.PublishFirstHatch(player: Player)", "\nend\n")
	check(has(publish, "if done.bank == true and done.hatch ~= true then true else nil")
			and has(data, "if milestone == \"bank\" or milestone == \"hatch\" then\n\t\tPlayerDataService.PublishFirstHatch(player)")
			and count(data, "PlayerDataService.PublishFirstHatch(player)") == 2,
		"the pending flag: from the first bank until the first hatch, published on load (a first pod from an "
			.. "earlier visit finds its card) and when either is recorded")
	local plant = sourceOf(Server, "PlantService")
	local verb = between(plant, "function PlantService.FirstHatch(player: Player, item: string)",
		"\n\tend\nend\n")
	local order = {
		"if PlayerDataService.TutorialDone(player, \"hatch\") ~= false then\n\t\t\treturn PlantService.HatchFromBag(player, item)",
		"return false, \"NO_POD\"",
		"if os.time() < due then\n\t\t\treturn false, \"NOT_READY\"",
		"return false, \"BUSY\"",
		"local bed = if soil and countIn(plot) < capacityOf(plot) then topOf(soil, spotsFor(plot, 1)[1]).Position",
		"landing = FirstHatchCard.landing(PlotService.SpawnCFrameFor(plot), bed)",
		"home = PlotService.TeleportTo(player, landing :: CFrame, \"TELEPORT_BLOCKED\")",
		"task.delay(if home then FIRST.HatchDelaySeconds else 0, function()",
		"local ok, code = PlantService.HatchFromBag(player, item)",
		"Metrics.firstHatchCard(player)",
		"channel:FireClient(player, BAG.Reply, { op = BAG.FirstHatch, item = item, ok = ok, code = code,",
		"return true, if home then \"HOME\" else \"HERE\", if home then landing else nil",
	}
	local at, inOrder, missing = 0, true, nil
	for _, text in ipairs(order) do
		local found = string.find(verb, text, 1, true)
		if not found or found < at then
			inOrder = false
			missing = missing or text
		else
			at = found
		end
	end
	check(verb ~= "" and inOrder,
		"the one tap: after the first hatch the Bag's verb answers; no pod, not ready or already asked is refused "
			.. "before anything moves; home by TELEPORT TO PLOT's rules, facing in; then the Bag's own hatch, "
			.. "counted, and its result told", missing)
	check(not has(verb, "TeleportHome"),
		"never TeleportHome: the guide's travel lesson (SELL, then TELEPORT TO PLOT) stays the buttons' to teach")
	check(has(plant, "if action == BAG.Hatch or action == BAG.Instant or action == BAG.FirstHatch then\n"
			.. "\t\tif type(payload) ~= \"string\" or #payload == 0 or #payload > 24 then")
			and has(plant, "elseif action == BAG.FirstHatch then\n\t\t\treply.ok, reply.code, reply.landing = "
				.. "PlantService.FirstHatch(player, payload)")
			and has(plant, "or action == BAG.OpenAll or action == BAG.FirstHatch then"),
		"off the wire: the item id a short string or nothing happens, through the Bag's own cooldown")

	--==========================================================================
	say("6. The clients")
	--==========================================================================
	local card = sourceOf(Scripts, "FirstHatchCard")
	check(card ~= "" and has(card, "player:GetAttribute(FIRST.PendingAttribute) == true")
			and has(card, "RewardMoments.busy(player, ATTR.OpenPanel)")
			and has(card, "tonumber(tool:GetAttribute(BAG.Attribute))") and has(card, "tool:GetAttribute(ATTR.ItemId)")
			and has(card, "local avoid = HudLayout.occupied(L)")
			and has(card, "for _, g in ipairs(UIKit.guideRects(playerGui, gui.AbsolutePosition)) do")
			and has(card, "FirstHatchCard.rect(L.safe, avoid)"),
		"the card reads the server's flag, the Bag's own Tools and the HUD's rects; it stands down for a menu "
			.. "or a reward moment")
	check(count(card, "FireServer(") == 1 and has(card, "ev:FireServer(BAG.FirstHatch, pod.item)")
			and has(card, "if pod.hatchAt > Workspace:GetServerTimeNow() then")
			and has(card, "if reply.ok == true and typeof(reply.landing) == \"CFrame\" then\n"
				.. "\t\t\tplayer:SetAttribute(FIRST.AskedAttribute, reply.landing)"),
		"its HATCH: one verb with the pod's item id, only once it is ready; the server's own landing noted for "
			.. "the camera")
	check(has(card, "\"FirstHatchButton\"") and has(card, "SoundKit.play(FIRST.Sound)")
			and has(card, "if card.Visible then") and has(card, "gui.DisplayOrder = 35")
			and count(card, "MenuKit.button(") == 1 and not has(card, "Instance.new(\"TextButton\")")
			and not has(card, "\"Dimmer\""),
		"a named HATCH for the guide's hand, the ping once as it turns ready in front of them, no close, no dimmer")
	local camera = sourceOf(Scripts, "ObbyCamera")
	check(has(camera, "local FIRST_ASKED = GameConfig.FirstHatch.AskedAttribute")
			and has(camera, "if typeof(landing) == \"CFrame\" and not ObbyData.onCourse(player) then\n"
				.. "\t\texpect(landing.Position, landing.LookVector, ObbyView.EntranceWaitSeconds)"),
		"the camera turns once into the garden when the body is put there")
	local guide = sourceOf(Scripts, "TutorialUI")
	check(has(guide, "local cardHatch = bagGuiButton(\"FirstHatchButton\")")
			and has(guide, "if left > 0 then\n\t\t\t\tpointAt(nil, \"\", nil, nil)")
			and has(guide, "pointAt(cardFrame, \"TAP HATCH\", nil, cardHatch)"),
		"the guide's hand: none while the card counts down, then on the card from outside it for its HATCH; "
			.. "the Bag's door when no card stands")
	local hatchStep = between(guide, "\tif id == \"hatch\" then\n", "\n\tend\n")
	local cardAt = string.find(hatchStep, "local cardHatch = bagGuiButton(\"FirstHatchButton\")", 1, true)
	local groundAt = string.find(hatchStep, "local pod = podIn(plot)", 1, true)
	check(cardAt and groundAt and cardAt < groundAt and count(guide, "bagGuiButton(\"FirstHatchButton\")") == 1
			and has(hatchStep, "local cardDue = bagPodDue()\n\t\tif cardDue and cardHatch and shown(cardHatch) "
				.. "and cardFrame and cardFrame:IsA(\"GuiObject\") then"),
		"the card comes first on the hatch step, before a pod in the ground (a new garden's starter pod hatches "
			.. "itself): one timer on screen, the card's")
	local loadout = sourceOf(Scripts, "LoadoutUI")
	check(has(loadout, "elseif player:GetAttribute(GameConfig.FirstHatch.PendingAttribute) ~= true then\n"
			.. "\t\t\tlocal credits = tonumber(player:GetAttribute(HATCH_BAG.CreditsAttribute)) or 0"),
		"no Instant Hatch (no Robux price) on a first pod")
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
pcall(function()
	Metrics.useSink(nil)
	Metrics.configure(nil)
	Metrics.useStaffCheck(nil)
	Metrics.useClock(nil)
	Metrics.useHeadcount(nil)
	Metrics.reset()
end)

say(string.format("\nFirstHatchSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
