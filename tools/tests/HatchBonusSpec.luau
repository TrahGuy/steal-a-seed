--!nocheck
--==============================================================================
-- Steal a Seed :: HatchBonusSpec
--
-- THE ONE-TIME HATCH BONUS AND THE LIKE REMINDER (2026-10-01, the owner's
-- brief; GameConfig.HatchBonus). Edit mode, on the REAL modules:
--
--   PlayerDataService  joined through its own Join, SaveService's Load and Save
--                      answered from a table here (InstantCreditSpec's way)
--   WheelService       GrantHatchBonus, its message heard through
--                      useBonusReply rather than the remote
--   ProfileSchema      the two saved fields
--   Notice             a notice the player may dismiss
--
-- What the brief asked to be checked: new and existing players, failed
-- hatches, repeated and simultaneous hatch events, saving and rejoining, and
-- leaving before the reminder appears. The presentation's timing is Play's
-- (KB/HANDOFF.md); its source is held here.
--
-- NOTHING IS BOUGHT AND NO SAVE IS OPENED.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local WheelData = require(Shared.WheelData)
local Notice = require(Shared.Notice)
local Server = game:GetService("ServerScriptService").SeedGameServer
local SaveService = require(Server.SaveService)
local PlotService = require(Server.PlotService)
local ProfileSchema = require(Server.ProfileSchema)
local PlayerDataService = require(Server.PlayerDataService)
local WheelService = require(Server.WheelService)

local BONUS = GameConfig.HatchBonus
local REMIND = BONUS.Reminder
local A = WheelData.Attributes

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
local function sourceOf(instance)
	if instance == nil then
		return nil
	end
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok then src else nil
end

local fixture = Instance.new("Folder")
fixture.Name = "HatchBonusSpecFixture"
fixture.Archivable = false
fixture.Parent = ServerStorage

--==============================================================================
-- THE STAND-INS (InstantCreditSpec's)
--==============================================================================
local real = {
	Load = SaveService.Load,
	Save = SaveService.Save,
	Forget = SaveService.Forget,
	SetDesiredLevel = PlotService.SetDesiredLevel,
	MountStats = PlayerDataService.MountStats,
}
local OFFLINE = 9809
local stored = {}
local writes = {}
SaveService.Load = function(userId)
	if userId == OFFLINE then
		return "unavailable", nil
	end
	local saved = stored[userId]
	if saved == nil then
		return "new", nil
	end
	return "ok", table.clone(saved)
end
SaveService.Save = function(userId, payload, release)
	stored[userId] = table.clone(payload)
	table.insert(writes, { userId = userId, earned = payload.WheelEarned, claimed = payload.HatchBonusClaimed,
		reminder = payload.LikeReminder, release = release == true })
	return true
end
SaveService.Forget = function() end
PlotService.SetDesiredLevel = function()
	return true
end
local holders = {}
PlayerDataService.MountStats = function(holder, profile)
	return real.MountStats(holders[holder] or holder, profile)
end

local joined = {}
local function stand(name, userId)
	local holder = Instance.new("Folder")
	holder.Name = name
	holder.Parent = fixture
	local characterAdded = Instance.new("BindableEvent")
	characterAdded.Parent = holder
	local character = Instance.new("Model")
	character.Name = name .. "Body"
	character.Parent = holder
	local attrs = {}
	local p = {
		Name = name,
		UserId = userId,
		Parent = Players,
		Character = character,
		CharacterAdded = characterAdded.Event,
		_holder = holder,
	}
	function p.SetAttribute(_, k, v)
		attrs[k] = v
	end
	function p.GetAttribute(_, k)
		return attrs[k]
	end
	function p.Kick() end
	function p.FindFirstChildOfClass()
		return nil
	end
	function p.WaitForChild(_, childName)
		return holder:FindFirstChild(childName)
	end
	function p.IsA(_, class)
		return class == "Player"
	end
	holders[p] = holder
	return p
end

local function join(name, userId)
	local p = stand(name, userId)
	PlayerDataService.Join(p)
	local deadline = os.clock() + 5
	while not PlayerDataService.IsReady(p) and os.clock() < deadline do
		task.wait(0.05)
	end
	table.insert(joined, p)
	return p, PlayerDataService.Get(p)
end

-- The bonus's messages, as the client would have been sent them.
local heard = {}
WheelService.useBonusReply(function(player, payload)
	table.insert(heard, { player = player, payload = payload })
end)
local function heardFor(p)
	local n, last = 0, nil
	for _, h in ipairs(heard) do
		if h.player == p then
			n += 1
			last = h.payload
		end
	end
	return n, last
end

local function settle()
	-- GrantHatchBonus saves off its own thread.
	task.wait(0.2)
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE WORDS, AS THE OWNER WROTE THEM
	--==========================================================================
	say("-- the words --")
	check(BONUS.FirstTitle == "FIRST HATCH BONUS!" and BONUS.WelcomeTitle == "WELCOME BACK BONUS!"
			and BONUS.Detail == "You earned 1 free wheel spin.",
		"FIRST HATCH BONUS! and WELCOME BACK BONUS!, both saying \"You earned 1 free wheel spin.\"")
	check(REMIND.Title .. " " .. REMIND.Detail == "ENJOYING PODNAPPERS? Leave us a like!",
		"the reminder says \"Enjoying Podnappers? Leave us a like!\"", REMIND.Title .. " " .. REMIND.Detail)
	local words = string.lower(REMIND.Title .. " " .. REMIND.Detail)
	check(not words:find("reward") and not words:find("spin") and not words:find("free")
			and not words:find("get ") and not words:find("win"),
		"and promises nothing for a like")

	--==========================================================================
	-- 2. THE SAVED FIELDS
	--==========================================================================
	say("\n-- the saved fields --")
	local d = ProfileSchema.Default()
	check(d.HatchBonusClaimed == false and d.LikeReminder == "", "a new profile has not claimed it, and no reminder")
	local old = ProfileSchema.Sanitise({})
	check(old.HatchBonusClaimed == false and old.LikeReminder == "",
		"an old save with neither field reads unclaimed: joining grants nothing by itself")
	local junk = ProfileSchema.Sanitise({ HatchBonusClaimed = "yes", LikeReminder = "liked" })
	check(junk.HatchBonusClaimed == false and junk.LikeReminder == "", "junk reads unclaimed, no reminder")
	local kept = ProfileSchema.Sanitise(ProfileSchema.Sanitise({ HatchBonusClaimed = true, LikeReminder = "pending" }))
	local shown = ProfileSchema.Sanitise({ HatchBonusClaimed = true, LikeReminder = "shown" })
	check(kept.HatchBonusClaimed == true and kept.LikeReminder == "pending" and shown.LikeReminder == "shown",
		"claimed, pending and shown round-trip unchanged")

	--==========================================================================
	-- 3. A NEW PLAYER'S FIRST HATCH
	--==========================================================================
	say("\n-- a new player --")
	local a, pa = join("BonusNew", 9801)
	check(pa ~= nil and PlayerDataService.IsPersistent(a) and pa.WheelEarned == 0 and pa.HatchBonusClaimed == false,
		"(the fixture: a new, saving profile with no spins)")
	local dayAt, dayCount = pa.WheelDayAt, pa.WheelDayCount
	local label = WheelService.GrantHatchBonus(a, true, 1234.5)
	local n, msg = heardFor(a)
	check(label == "first" and pa.WheelEarned == 1 and pa.HatchBonusClaimed == true and pa.LikeReminder == "pending",
		"a first-ever hatch: one spin on the EARNED balance, claimed, the reminder pending -- FIRST HATCH BONUS!",
		string.format("%s %s %s %s", tostring(label), tostring(pa.WheelEarned), tostring(pa.HatchBonusClaimed),
			tostring(pa.LikeReminder)))
	check(pa.WheelDayAt == dayAt and pa.WheelDayCount == dayCount and pa.WheelBought == 0,
		"the obby's daily allowance and the bought balance are untouched")
	check(n == 1 and msg and msg.label == "first" and msg.revealAt == 1234.5,
		"the client is told once, with the label and when the plant shows", n)
	check(a:GetAttribute(A.Earned) == 1 and a:GetAttribute(GameConfig.Attributes.LikeReminder) == "pending",
		"and its spin count and the reminder's state are published at once")
	settle()
	local w = writes[#writes]
	check(w ~= nil and w.userId == 9801 and w.earned == 1 and w.claimed == true and w.reminder == "pending",
		"a save follows, with the spin, the marker and the reminder together",
		w and string.format("%s %s %s", tostring(w.earned), tostring(w.claimed), tostring(w.reminder)))

	--==========================================================================
	-- 4. REPEATED HATCHES, AND TWO AT ONCE
	--==========================================================================
	say("\n-- repeated and simultaneous --")
	local again = WheelService.GrantHatchBonus(a, false, 1300)
	local again2 = WheelService.GrantHatchBonus(a, true, 1400)
	check(again == nil and again2 == nil and pa.WheelEarned == 1 and select(1, heardFor(a)) == 1,
		"every later hatch -- either label -- gives nothing and says nothing", pa.WheelEarned)
	local t, pt = join("BonusTwin", 9802)
	local results = {}
	local done = 0
	for i = 1, 4 do
		task.spawn(function()
			results[i] = WheelService.GrantHatchBonus(t, i % 2 == 1, 50)
			done += 1
		end)
	end
	local deadline = os.clock() + 2
	while done < 4 and os.clock() < deadline do
		task.wait()
	end
	local given = 0
	for i = 1, 4 do
		if results[i] ~= nil then
			given += 1
		end
	end
	check(done == 4 and given == 1 and pt.WheelEarned == 1 and select(1, heardFor(t)) == 1,
		"four hatch events at once: exactly one bonus, one spin, one message", given)

	--==========================================================================
	-- 5. AN EXISTING PLAYER
	--==========================================================================
	say("\n-- an existing player --")
	local b, pb = join("BonusOld", 9803)
	pb.WheelEarned = 3
	local lb = WheelService.GrantHatchBonus(b, false, 77)
	local _, mb = heardFor(b)
	check(lb == "welcome" and pb.WheelEarned == 4 and pb.HatchBonusClaimed and mb and mb.label == "welcome",
		"a player whose record had hatched before gets the same one spin on their next hatch -- WELCOME BACK BONUS!",
		pb.WheelEarned)

	--==========================================================================
	-- 6. THE ALLOWANCE IS NOT THE BONUS'S, AND THE BALANCE'S CAP IS RESPECTED
	--==========================================================================
	say("\n-- the obby's allowance, and a full balance --")
	local c, pc = join("BonusObby", 9804)
	local now = os.time()
	pc.WheelDayAt, pc.WheelDayCount = now, WheelData.Daily.Limit
	check(WheelService.GrantHatchBonus(c, true, 1) == "first" and pc.WheelEarned == 1
			and pc.WheelDayCount == WheelData.Daily.Limit and pc.WheelDayAt == now,
		"with the day's obby spins all used, the bonus still lands and uses none of tomorrow's")
	local outcome = WheelService.AwardCompletion(c, "spec-run-1", 0)
	check(outcome ~= "spin" and pc.WheelEarned == 1, "and the obby's own limit still holds after it", outcome)
	local f, pf = join("BonusFull", 9805)
	pf.WheelEarned = WheelData.MaxEarnedHeld
	check(WheelService.GrantHatchBonus(f, true, 1) == nil and pf.HatchBonusClaimed == false
			and pf.LikeReminder == "" and pf.WheelEarned == WheelData.MaxEarnedHeld,
		"a full earned balance claims nothing yet -- a spin past the cap would vanish on the next join")
	pf.WheelEarned -= 1
	check(WheelService.GrantHatchBonus(f, true, 1) == "first" and pf.HatchBonusClaimed
			and pf.WheelEarned == WheelData.MaxEarnedHeld,
		"and the next hatch with room claims it")
	local o, po = join("BonusOffline", OFFLINE)
	check(po ~= nil and not PlayerDataService.IsPersistent(o) and WheelService.GrantHatchBonus(o, true, 1) == nil
			and po.HatchBonusClaimed == false and po.WheelEarned == 0,
		"a profile that is not saving claims nothing, rather than a spin that vanishes with the server")

	--==========================================================================
	-- 7. A RESET, A REJOIN, AND LEAVING BEFORE THE REMINDER
	--==========================================================================
	say("\n-- reset, rejoin, and leaving early --")
	check(PlayerDataService.ResetProgress(b) and PlayerDataService.Get(b).HatchBonusClaimed == true
			and PlayerDataService.Get(b).LikeReminder == "pending" and PlayerDataService.Get(b).WheelEarned == 0,
		"an admin's progress reset keeps the marker and the reminder (the earned spins reset, as all progress does)")
	check(WheelService.GrantHatchBonus(b, true, 1) == nil and PlayerDataService.Get(b).WheelEarned == 0,
		"and the bonus cannot be claimed again after it")
	-- A leaves after the bonus and before the reminder came up.
	PlayerDataService.Leave(a)
	local lw = writes[#writes]
	check(lw and lw.userId == 9801 and lw.claimed == true and lw.reminder == "pending" and lw.release == true,
		"the leave save keeps it claimed, its reminder still pending")
	local a2, pa2 = join("BonusNew", 9801)
	check(pa2 ~= nil and pa2.HatchBonusClaimed == true and pa2.LikeReminder == "pending" and pa2.WheelEarned == 1,
		"the next join reads back the spin, the marker and the pending reminder")
	check(a2:GetAttribute(GameConfig.Attributes.LikeReminder) == "pending",
		"and publishes the pending reminder, for this visit to show at a calm moment")
	check(WheelService.GrantHatchBonus(a2, false, 1) == nil and pa2.WheelEarned == 1,
		"a hatch on the rejoined profile gives nothing more: a pending reminder never grants a spin")
	check(PlayerDataService.MarkLikeReminderShown(a2) and pa2.LikeReminder == "shown" and pa2.WheelEarned == 1
			and a2:GetAttribute(GameConfig.Attributes.LikeReminder) == "shown",
		"shown: the state moves on and nothing else changes")
	check(not PlayerDataService.MarkLikeReminderShown(a2) and pa2.LikeReminder == "shown",
		"marking it shown again changes nothing")
	local never, pn = join("BonusNever", 9806)
	check(not PlayerDataService.MarkLikeReminderShown(never) and pn.LikeReminder == "",
		"a player who never earned the bonus cannot mark a reminder shown")

	--==========================================================================
	-- 8. WHAT THE SOURCE SAYS
	--==========================================================================
	say("\n-- the source --")
	local plant = sourceOf(Server.PlantService) or ""
	-- Declared ahead (`local hatch: ...`) and defined as `function hatch(`.
	local body = string.match(plant, "\nfunction hatch%((.-)\nend\n") or ""
	local gave = body:find("if not given then", 1, true)
	local first = body:find("local firstHatch = PlayerDataService.RecordTutorial(player, \"hatch\")", 1, true)
	local announce = body:find("announceReveal({", 1, true)
	check(gave and first and announce and gave < first and first < announce
			and body:find("firstHatch = firstHatch == true", 1, true) ~= nil,
		"in PlantService's hatch, a refused hatch returns before the hatch is recorded or announced; the first-ever "
			.. "answer is taken where the hatch is recorded and rides on the reveal")
	local wheel = sourceOf(Server.WheelService) or ""
	check(wheel:find("unhookReveal = PlantService.OnRevealed(", 1, true) ~= nil
			and wheel:find("WheelService.GrantHatchBonus(owner, reveal.firstHatch == true, reveal.revealAt)", 1, true) ~= nil,
		"WheelService hears every successful hatch through PlantService's own reveal hook")
	local grant = string.match(wheel, "function WheelService%.GrantHatchBonus(.-)\nend\n") or ""
	check(grant ~= "" and not grant:find("WheelDayCount", 1, true) and not grant:find("WheelDayAt", 1, true)
			and not grant:find("WheelBought", 1, true) and grant:find("p.WheelEarned += 1", 1, true) ~= nil
			and grant:find("task.wait", 1, true) == nil,
		"the grant writes the earned balance only, never the daily allowance or the bought balance, and never yields")
	local pds = sourceOf(Server.PlayerDataService) or ""
	local reset = string.match(pds, "function PlayerDataService%.ResetProgress(.-)\nend\n") or ""
	check(reset:find("HatchBonusClaimed = ", 1, true) ~= nil and reset:find("LikeReminder = ", 1, true) ~= nil,
		"the reset names the marker and the reminder among what it keeps")
	check(pds:find("if action == GameConfig.HatchBonus.Reminder.Action then", 1, true) ~= nil
			and pds:find("PlayerDataService.MarkLikeReminderShown(player)", 1, true) ~= nil,
		"the client's \"shown\" verb carries nothing and only moves the reminder on")

	--==========================================================================
	-- 9. THE NOTICE THE PLAYER MAY DISMISS, AND THE CLIENT'S TIMING
	--==========================================================================
	say("\n-- the reminder's notice, and the client --")
	check(Notice.holdFor({ kind = "info", title = "T", seconds = REMIND.Seconds, dismissible = true }) == REMIND.Seconds
			and Notice.holdFor({ kind = "info", title = "T", seconds = REMIND.Seconds }) == Notice.MaxSeconds,
		"a dismissible notice may stay up its full time; any other is still held to MaxSeconds")
	check(Notice.valid({ kind = "info", title = "T", dismissible = true, onDismissed = function() end })
			and not Notice.valid({ kind = "info", title = "T", dismissible = "yes" }),
		"and Notice checks the new fields")
	local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	local toast = sourceOf(scripts and scripts:FindFirstChild("ActionToastUI")) or ""
	check(toast:find("close.Selectable = true", 1, true) ~= nil and toast:find("close.Size = UDim2.fromOffset(44, 44)", 1, true) ~= nil
			and toast:find("close.Activated:Connect(function()", 1, true) ~= nil
			and toast:find("leave(d, Notice.ExitSeconds)", 1, true) ~= nil,
		"ActionToastUI draws its close button: a 44 px press the UI's selection can reach, leaving like any notice")
	local ui = sourceOf(scripts and scripts:FindFirstChild("HatchBonusUI")) or ""
	local _, fires = string.gsub(ui, "FireServer%(", "")
	check(ui:find("HATCH.Reveal.Seconds + HATCH.Label.Seconds + HATCH.Label.FadeSeconds", 1, true) ~= nil
			and ui:find("guidePanel(\"Celebration\")", 1, true) ~= nil
			and ui:find("kind = \"success\", title = label, detail = BONUS.Detail", 1, true) ~= nil,
		"HatchBonusUI waits for the roll, the reveal and the guide's congratulations, then posts the success notice")
	check(ui:find("dismissible = true", 1, true) ~= nil and ui:find("kind = \"info\"", 1, true) ~= nil
			and fires == 1 and ui:find("remote:FireServer(REMIND.Action)", 1, true) ~= nil,
		"the reminder is a dismissible info notice, and the only thing sent is the bare \"shown\"", fires)
	check(not ui:lower():find("i liked", 1, true) and not ui:find("PromptSetFavorite", 1, true),
		"no \"I liked it\" button and no like detection")
end)

WheelService.useBonusReply(nil)
for _, p in ipairs(joined) do
	if PlayerDataService.IsReady(p) then
		pcall(PlayerDataService.Leave, p)
	end
end
SaveService.Load, SaveService.Save, SaveService.Forget = real.Load, real.Save, real.Forget
PlotService.SetDesiredLevel = real.SetDesiredLevel
PlayerDataService.MountStats = real.MountStats
fixture:Destroy()

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nHatchBonusSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
