--!nocheck
--==============================================================================
-- Steal a Seed :: TreadmillFunSpec
-- TREADMILL FUN (the owner's brief, 2026-10-08). Edit mode:
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("TreadmillFunSpec"))
--
-- The owner's checks:
--   pops        the whole-number crossings of walkSpeedFor, several merged
--   milestones  the list; each pays once; a gain crossing several pays all in
--               one notice; admin and debug pay nothing; no back pay on
--               migration; the 5 ticket milestones; the cash, its floor and
--               the cap
--   the catch   one item per 8-12 s; the server decides a catch (no client
--               claim exists); one golden ticket per rolling 24 h; nothing
--               while carrying, on the Disco Mill or during the two mini event
--               modes; the path clears all 14 tiers on all 6 plots
--   unchanged   the belt's Speed rate
-- plus the saves (a full existing profile loads the same but for the passed
-- milestones) and the icons the addenda split (Speed and the training boost).
--
-- THE REAL TreadmillFunService, loaded from its Source with PlayerDataService,
-- PlotService, EconomyService, TreadmillService, CarryService, WheelService
-- and Players stood in -- they record what they are asked: no save, no cash,
-- no spin is real. Its clock, its notices and the next item's kind go through
-- its Studio seams. A real belt part (tagged, far above the map) and a real
-- character model stand in for a mill and a player. Simulated user ids only.
-- The path sweep builds every tier's real mill on every plot of the ring, as
-- MillPlacementSpec does. Not here: what any of it looks like (the Play).
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SpeedMilestones = require(Shared:WaitForChild("SpeedMilestones"))
local BeltCatch = require(Shared:WaitForChild("BeltCatch"))
local MillModel = require(Shared:WaitForChild("MillModel"))
local ShopCatalog = require(Shared:WaitForChild("ShopCatalog"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Schema = require(Server:WaitForChild("ProfileSchema"))
local MapService = require(Server:WaitForChild("MapService"))

local ATTR = GameConfig.Attributes
local EVENT = GameConfig.MiniEvent.Attributes

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
	local ok, src = pcall(function()
		return (found :: any).Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end

local Scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")

--==============================================================================
-- 1. THE POPS
--==============================================================================
say("-- the pops --")
do
	check(GameConfig.walkSpeedFor(0) == 16 and math.floor(GameConfig.walkSpeedFor(2)) == 16
		and math.floor(GameConfig.walkSpeedFor(3)) == 17, "Speed 2 walks 16.x, Speed 3 walks 17.x")
	local g, now = SpeedMilestones.walkGain(2, 3)
	check(g == 1 and now == 17, "so 2 -> 3 is one pop: +1, now 17", string.format("%d %d", g, now))
	local g0 = SpeedMilestones.walkGain(0, 2)
	check(g0 == 0, "0 -> 2 passes no whole number: no pop", g0)
	local big, at = SpeedMilestones.walkGain(0, 1000)
	check(big == 6 and at == 22, "0 -> 1,000 in one gain is ONE pop of +6, now 22", string.format("%d %d", big, at))
	local sum = 0
	local s = 0
	while s < 1000 do
		local nextS = math.min(1000, s + 7)
		sum += (SpeedMilestones.walkGain(s, nextS))
		s = nextS
	end
	check(sum == 6, "and gains of 7 at a time add up to the same six", sum)
	check(SpeedMilestones.popWords(1, 19) == "+1 WALK SPEED \u{00B7} NOW 19"
		and SpeedMilestones.popWords(3, 22) == "+3 WALK SPEED \u{00B7} NOW 22", "the words: +1 WALK SPEED · NOW 19")
	local ui = sourceOf(Scripts, "TreadmillFunUI")
	check(has(ui, "SpeedMilestones.walkGain(lastSpeed, s)") and has(ui, "local s = tonumber(profile.Speed)"),
		"the client pops off the SCORE in the profile packet (never the carry-slowed WalkSpeed)")
	check(has(ui, "popGained += gained"), "several in a row add into the one pop")
	check(has(ui, "gui.DisplayOrder = 11"), "drawn at DisplayOrder 11, under the notices (13) and the HUD (20)")
end

--==============================================================================
-- 1b. CLEAR OF THE HUD (the guarded Play, 2026-10-08: a close camera put the bar
-- at the top edge, behind the clock and the top row)
--==============================================================================
say("\n-- clear of the HUD --")
do
	local function R(x, y, w, h)
		return { x = x, y = y, w = w, h = h }
	end
	local function apart(a, b, gap)
		return not (a.x < b.x + b.w + gap and b.x < a.x + a.w + gap and a.y < b.y + b.h + gap and b.y < a.y + a.h + gap)
	end
	-- HudLayout's rects on that Play's desktop (1009 x 716, topbar 58), in the bar
	-- gui's pixels: both columns and INVITE's badge, the strip and its bands, the
	-- top row (BIOMES, TELEPORT TO PLOT, OBBY) with its status, notice and boost
	-- bands, the clock and ADMIN.
	local hud = {
		R(12, 70, 130, 266), R(947, 70, 50, 106), R(130, 642, 750, 64), R(12, 498, 232, 110),
		R(947, 184, 50, 50), R(126, 54, 31, 31), R(130, 616, 750, 22), R(334, 556, 340, 52),
		R(406, 88, 196, 44), R(610, 88, 124, 44), R(278, 88, 120, 44),
		R(406, 94, 196, 32), R(406, 50, 196, 30), R(406, 140, 196, 26),
		R(324, 8, 360, 34), R(692, 8, 64, 34),
	}
	local safe = R(0, 58, 1009, 658)
	-- The bar with its badge's room (303 x 68 drawn, 386 x 83 kept) where the
	-- close camera of capture 01 projected it: over the top edge.
	local bar = SpeedMilestones.clearOf(R(213, -2, 386, 83), hud, safe, 8)
	check(bar ~= nil and bar.x == 213 and bar.y == 174,
		"a bar projected at the top edge comes down under the top row and its boost band, over the same spot",
		bar and string.format("%s,%s", bar.x, bar.y))
	local open = SpeedMilestones.clearOf(R(300, 250, 386, 83), hud, safe, 8)
	check(open ~= nil and open.x == 300 and open.y == 250, "where nothing stands it stays where the belt puts it")
	local beside = SpeedMilestones.clearOf(R(130, 200, 200, 40), hud, safe, 8)
	check(beside ~= nil and beside.x == 150 and beside.y == 200, "over the left column by a little: steps right, the shortest way")
	-- Up costs double: the shorter way up loses to a way down under twice it.
	local floor = { R(0, 600, 1009, 50) }
	local room = R(0, 0, 1009, 700)
	local upWin = SpeedMilestones.clearOf(R(100, 570, 100, 40), floor, room, 8)
	check(upWin ~= nil and upWin.y == 552, "up when down is more than twice as far", upWin and upWin.y)
	local downWin = SpeedMilestones.clearOf(R(100, 590, 100, 40), floor, room, 8)
	check(downWin ~= nil and downWin.y == 658, "down when up is shorter but not half as far (up is dearer)", downWin and downWin.y)
	check(SpeedMilestones.clearOf(R(0, 0, 2000, 10), {}, safe, 8) == nil, "too big for the safe area: no place, so hidden")
	-- The pop's words under a bar that stands over them.
	local blocked = table.clone(hud)
	table.insert(blocked, bar)
	local words = SpeedMilestones.clearOf(R(250, 180, 385, 37), blocked, safe, 8)
	check(words ~= nil and words.y >= bar.y + bar.h + 8 and apart(words, bar, 8),
		"the pop's words come out under the bar, never over it", words and words.y)
	-- Every spot the belt could put the bar on that screen: clear of all of it, or hidden.
	local placed, hidden, bad = 0, 0, 0
	for x = -200, 1200, 25 do
		for y = -100, 760, 25 do
			local r = SpeedMilestones.clearOf(R(x, y, 386, 83), hud, safe, 8)
			if r == nil then
				hidden += 1
			else
				placed += 1
				local ok = r.x >= safe.x and r.y >= safe.y and r.x + r.w <= safe.x + safe.w and r.y + r.h <= safe.y + safe.h
				for _, b in ipairs(hud) do
					if not apart(r, b, 8) then
						ok = false
					end
				end
				if not ok then
					bad += 1
				end
			end
		end
	end
	check(bad == 0, string.format("all %d placements on that desktop stand clear of every HUD rect, inside the safe area", placed), bad)
	check(hidden == 0, "and none of the spots leaves it nowhere to stand", hidden)
	-- HudLayoutSpec's phones and two desktops, solved by HudLayout itself and
	-- turned into the bar gui's pixels exactly as TreadmillFunUI's measureHud
	-- does (a 58-px topbar; a notch moves the safe area right).
	local HudLayout = require(Shared:WaitForChild("HudLayout"))
	local TOPBAR = 58
	local screens = {
		{ "1280x720", 1280, 720, {} }, { "1920x1080", 1920, 1080, {} },
		{ "iPhone 11 896x414", 896, 414, { touch = true } },
		{ "iPhone 11 896x414 notched", 896, 414, { touch = true, left = 48, right = 48, bottom = 21 } },
		{ "iPhone 16 Pro Max 956x440", 956, 440, { touch = true } },
		{ "Galaxy S22 Ultra 772x360", 772, 360, { touch = true } },
		{ "VGA 640x480", 640, 480, { touch = true } },
		{ "the owner's 801x392", 801, 392, { touch = true } },
		{ "Studio 705x338", 705, 338, { touch = true } },
		{ "844x390 notched", 844, 390, { touch = true, left = 47, right = 47, bottom = 21 } },
		{ "640x360", 640, 360, { touch = true } },
	}
	for _, s in ipairs(screens) do
		local tag, w, h, o = s[1], s[2], s[3], s[4]
		local left, right, bottom = o.left or 0, o.right or 0, o.bottom or 0
		local input = {
			safe = Vector2.new(w - left - right, h - TOPBAR - bottom),
			touch = o.touch == true,
			keyboard = true,
			viewport = Vector2.new(w, h),
			topbar = { x = 208, y = 0, w = w - 208, h = TOPBAR },
			insetTop = TOPBAR,
		}
		local L = HudLayout.solve(input)
		local rects = {}
		local function add(r, lift)
			if r and r.w > 0 and r.h > 0 then
				table.insert(rects, R(r.x + left, r.y - (lift or 0) + TOPBAR, r.w, r.h))
			end
		end
		for _, r in ipairs(HudLayout.occupied(L)) do
			add(r)
		end
		local st, no, bo = HudLayout.statusRows(L, TOPBAR)
		add(st)
		add(no)
		add(bo)
		add(L.clock, TOPBAR)
		add(L.admin, TOPBAR)
		local bounds = R(left, TOPBAR, input.safe.X, input.safe.Y)
		local k = math.clamp(math.min(w / 1100, h / 720), 0.6, 1.25)
		local bw, bh = (330 + 90) * k, (74 + 16) * k
		local nPlaced, nHidden, nBad = 0, 0, 0
		for x = -100, w + 100, 20 do
			for y = -100, h + 100, 20 do
				local r = SpeedMilestones.clearOf(R(x, y, bw, bh), rects, bounds, 8)
				if r == nil then
					nHidden += 1
				else
					nPlaced += 1
					for _, b in ipairs(rects) do
						if not apart(r, b, 8) then
							nBad += 1
							break
						end
					end
				end
			end
		end
		check(nBad == 0 and nHidden == 0,
			string.format("%s: the bar (%dx%d) finds a clear place from all %d spots", tag, math.floor(bw), math.floor(bh), nPlaced + nHidden),
			string.format("%d overlapping, %d hidden", nBad, nHidden))
	end
	local ui = sourceOf(Scripts, "TreadmillFunUI")
	check(has(ui, "gui.ScreenInsets = Enum.ScreenInsets.None") and has(ui, "HudLayout.occupied(L)")
			and has(ui, "HudLayout.statusRows(L, insetTop)"),
		"the client places both off HudLayout's own rects, in a gui that is the whole screen")
	check(has(ui, "table.insert(blocked, barRect)"), "and the pop stands clear of the bar")
	-- SOLID AGAIN (the owner, 2026-10-10: "progress bars must not be transparent"): a dark well with a gold
	-- edge, the gold fill outlined on it.
	check(has(ui, "track.BackgroundColor3 = WELL") and has(ui, "track.BackgroundTransparency = 0")
			and not has(ui, "track.BackgroundTransparency = 1") and not has(ui, "track.BackgroundTransparency = 0.")
			and has(ui, "UIKit.corner(track, 8)") and has(ui, "UIKit.stroke(track, GOLD, 2)")
			and has(ui, "UIKit.stroke(fill, Color3.new(0, 0, 0), 1.5)"),
		"the bar has a solid dark track with a gold edge, the gold fill outlined in black on it")
	-- And the guide's card, which TutorialUI draws over this gui (in the v1048 Play the bar stood among its words).
	check(has(ui, "local more = UIKit.guideRects(playerGui, origin)") and has(ui, "aroundNow(t),")
			and has(ui, "local blocked = aroundNow(t)"),
		"the bar and the pop keep clear of the guide's card while it shows")
	-- And of the Pod Rush tracker or its strip, under the top row as well (a Play on 2026-10-10: the bar at the
	-- top centre stood on the tracker). Its gui and frames by name, so a rename there fails here.
	local rushUi = sourceOf(Scripts, "PodRushUI")
	check(has(ui, "local RUSH_PIECES = { \"Tracker\", \"Strip\" }")
			and has(ui, "local rush = playerGui:FindFirstChild(\"SeedPodRush\")")
			and has(ui, "if piece and piece:IsA(\"GuiObject\") and piece.Visible then")
			and has(rushUi, "local gui = newGui(\"SeedPodRush\", 12)") and has(rushUi, "tracker.Name = \"Tracker\"")
			and has(rushUi, "strip.Name = \"Strip\"") and has(rushUi, "tracker.Parent = gui")
			and has(rushUi, "strip.Parent = gui"),
		"and of the Pod Rush tracker or its strip while either shows")
	-- The queue after v1048: "make the bar show while the player is on or by their own mill". In Play, 12 studs
	-- beside the belt put its point behind the camera, and the bar hid.
	check(has(ui, "local at: Vector2 = if over and over.X >= bounds.x and over.X <= bounds.x + bounds.w")
			and has(ui, "else Vector2.new(bounds.x + bounds.w / 2, bounds.y + h + rise)")
			and not has(ui, "if at and at.X >= bounds.x and at.X <= bounds.x + bounds.w then"),
		"within 45 studs of the own belt the bar always shows: over the belt, or at the top centre when the belt is "
			.. "behind the camera or off to a side")
	do
		local UIKit = require(Shared:WaitForChild("UIKit"))
		local stand = Instance.new("Folder")
		stand.Name = "TreadmillFunSpecPlayerGui"
		local guide = Instance.new("ScreenGui")
		guide.Name = "SeedBeginnerGuide"
		guide.Parent = stand
		local card = Instance.new("Frame")
		card.Name = "Words"
		card.Parent = guide
		local banner = Instance.new("Frame")
		banner.Name = "Instruction"
		banner.Parent = card
		local skip = Instance.new("TextButton")
		skip.Name = "Skip"
		skip.Parent = card
		local resume = Instance.new("TextButton")
		resume.Name = "Resume"
		resume.Visible = false
		resume.Parent = card
		local origin = Vector2.new(10, 20)
		local shown = UIKit.guideRects(stand, origin)
		local first = shown[1]
		local p, s = banner.AbsolutePosition, banner.AbsoluteSize
		local okShown = #shown == 2 and first ~= nil and first.x == p.X - 10 and first.y == p.Y - 20
			and first.w == s.X and first.h == s.Y and UIKit.guideShowing(stand)
		card.Visible = false
		local okHidden = #UIKit.guideRects(stand, origin) == 0 and not UIKit.guideShowing(stand)
		card.Visible = true
		guide.Enabled = false
		local okOff = #UIKit.guideRects(stand, origin) == 0 and not UIKit.guideShowing(stand)
		stand:Destroy()
		check(okShown and okHidden and okOff,
			"UIKit.guideRects: each shown banner, SKIP or RESUME, less the origin; none while hidden or off",
			string.format("shown %d, hidden %s, off %s", #shown, tostring(okHidden), tostring(okOff)))
	end
end

--==============================================================================
-- 2. THE MILESTONES
--==============================================================================
say("\n-- the milestones --")
do
	local want = { 100, 500, 1e3, 5e3, 1e4, 5e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13, 1e14, 1e15 }
	local same = #SpeedMilestones.List == 17
	for i, m in ipairs(want) do
		if SpeedMilestones.List[i] ~= m then
			same = false
		end
	end
	check(same, "the seventeen, in order: 100 .. 1Qa")
	local tickets, cash, floorsUp = {}, 0, true
	local lastFloor = 0
	for _, m in ipairs(SpeedMilestones.List) do
		if SpeedMilestones.isTicket(m) then
			table.insert(tickets, SpeedMilestones.label(m))
		else
			cash += 1
			local f = SpeedMilestones.Floors[m]
			if not f or f <= lastFloor then
				floorsUp = false
			end
			lastFloor = f or lastFloor
		end
	end
	check(table.concat(tickets, ",") == "1K,1M,1B,1T,1Qa", "one spin ticket at 1K, 1M, 1B, 1T and 1Qa", table.concat(tickets, ","))
	check(cash == 12 and floorsUp, "cash at the other twelve, each with a floor that grows with the milestone")
	local c = SpeedMilestones.crossed(0, 1200)
	check(#c == 3 and c[1] == 100 and c[3] == 1000, "0 -> 1,200 crosses 100, 500 and 1K")
	check(#SpeedMilestones.crossed(1000, 1200) == 0 and SpeedMilestones.crossed(999, 1000)[1] == 1000
		and #SpeedMilestones.crossed(5e15, 9e15) == 0, "at or below the mark is spent; exactly on one crosses it")
	check(SpeedMilestones.capFor(1) == 2500 and SpeedMilestones.capFor(4) == 2500000 and SpeedMilestones.capFor(7) == 250000000,
		"the cap: a tenth of the next plot level (25K -> 2.5K), of the top one at Level 7")
	check(SpeedMilestones.cashFor(100, 0, 1) == 100, "a new player at 100 Speed: the $100 floor")
	check(SpeedMilestones.cashFor(5e3, 50, 1) == 2500, "60 s of $50/s ($3,000) is over a Level 1 cap: $2,500")
	check(SpeedMilestones.cashFor(5e3, 30, 2) == 1800, "60 s of $30/s beats the 5K floor: $1,800")
	check(SpeedMilestones.cashFor(1e5, 1e6, 1) == 2500, "a huge income on a Level 1 plot is capped at a tenth of 25K")
	check(SpeedMilestones.cashFor(1e8, 0, 1) == 2500, "and the cap wins over a floor too")
	local capped = true
	for _, m in ipairs(SpeedMilestones.List) do
		if not SpeedMilestones.isTicket(m) then
			for level = 1, #GameConfig.PlotTiers do
				local nextCost = (GameConfig.PlotTiers[level + 1] or GameConfig.PlotTiers[#GameConfig.PlotTiers]).cost
				if SpeedMilestones.cashFor(m, 1e15, level) > nextCost * 0.10 then
					capped = false
				end
			end
		end
	end
	check(capped, "no milestone ever pays more than a tenth of the next plot level's cost")
	check(SpeedMilestones.barWords(1e3) == "NEXT: 1K SPEED \u{00B7} 1 SPIN TICKET"
		and SpeedMilestones.barWords(5e3) == "NEXT: 5K SPEED \u{00B7} CASH"
		and SpeedMilestones.barWords(nil) == "EVERY SPEED MILESTONE PASSED", "the bar's words")
	local last, nextOne, fill = SpeedMilestones.progress(1000, 3000)
	check(last == 1000 and nextOne == 5000 and math.abs(fill - 0.5) < 1e-9, "and its fill: 3K between 1K and 5K is half")
	local t1, d1 = SpeedMilestones.noticeWords(1e4, 2000, 0)
	local t2, d2 = SpeedMilestones.noticeWords(1e3, 350, 1)
	check(t1 == "MILESTONE! 10K Speed" and d1 == "+$2K" and t2 == "MILESTONE! 1K Speed"
		and d2 == "+$350 \u{00B7} +1 Spin Ticket", "the notice: MILESTONE! 10K Speed / +$2K", d2)
end

--==============================================================================
-- 3. THE SAVES
--==============================================================================
say("\n-- the saves --")
do
	local d = Schema.Default()
	check(d.SpeedMilestone == 0 and d.MilestoneSpinsOwed == 0 and d.BeltTicketAt == 0 and d.BeltTicketCount == 0,
		"a new profile: nothing passed, nothing owed, no ticket window")
	check(Schema.Sanitise({ Speed = 0 }).SpeedMilestone == 0, "an old save at Speed 0 has passed nothing")
	check(Schema.Sanitise({ Speed = 2.5e6 }).SpeedMilestone == 1e6,
		"an old save at 2.5M has passed up to 1M already -- no back pay")
	check(Schema.Sanitise({ Speed = 2.5e6, SpeedMilestone = 1e5 }).SpeedMilestone == 1e5,
		"a save that has the key is read as it stands")
	check(Schema.Sanitise({ Speed = 2.5e6, SpeedMilestone = "x" }).SpeedMilestone == 1e6, "junk is treated as no key")
	local j = Schema.Sanitise({ MilestoneSpinsOwed = 9, BeltTicketAt = os.time() + 1e6, BeltTicketCount = 5 })
	check(j.MilestoneSpinsOwed == 5 and j.BeltTicketAt <= os.time() and j.BeltTicketCount == 1,
		"owed spins cap at 5; a ticket window can't start in the future; the count caps at 1")
	check(Schema.Sanitise({ BeltTicketCount = 1 }).BeltTicketCount == 0, "a count with no window is none")

	local T = 1760000000
	-- A save at the current schema version (an unversioned one is migrated by
	-- the older plot-level rule, which is not this brief's).
	local raw = {
		Version = GameConfig.Save.CurrentVersion,
		Cash = 123456, Speed = 3.2e7, PlotTier = 4, MillTier = 6, WheelEarned = 7,
		Almanac = { nubkin = true, spiretip = true },
		Plants = { { SpeciesId = "nubkin", Tier = 2, PlantedAt = T, HatchAt = T + 60, X = 1, Z = 2, Stage = 3, Item = "7" } },
		Held = { { Id = "spiretip", Tier = 3, Hatched = true, Item = "8" } },
		Tutorial = { Version = 3, Done = { train = true, speed = true, steal = true, bank = true, place = true, hatch = true },
			Skipped = false, PodGrants = 1 },
	}
	local p = Schema.Sanitise(raw)
	check(p.Cash == 123456 and p.Speed == 3.2e7 and p.PlotTier == 4 and p.MillTier == 6 and p.WheelEarned == 7
			and #p.Plants == 1 and #p.Held == 1 and p.Almanac.spiretip == true and p.Tutorial.Done.hatch == true,
		"a full existing profile loads with every field as it was")
	check(p.SpeedMilestone == 1e7 and p.MilestoneSpinsOwed == 0 and p.BeltTicketAt == 0,
		"apart from the milestones under its 32M Speed, marked passed (to 10M)")
	local data = sourceOf(Server, "PlayerDataService")
	check(has(data, "SpeedMilestone = math.max(0, tonumber(profile.SpeedMilestone) or 0),")
			and has(data, "BeltTicketAt = math.max(0, math.floor(tonumber(profile.BeltTicketAt) or 0)),"),
		"a progress reset keeps the mark and the ticket window: a milestone pays once per profile, ever")
end

--==============================================================================
-- THE SERVICE, ON STAND-INS
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = table.pack(...) })
end
local function count(name)
	local n = 0
	for _, t in trace do
		if t.name == name then
			n += 1
		end
	end
	return n
end
local function last(name)
	for i = #trace, 1, -1 do
		if trace[i].name == name then
			return trace[i]
		end
	end
	return nil
end

local fixture = Instance.new("Folder")
fixture.Name = "TreadmillFunSpecFixture"
fixture.Parent = ServerStorage

local fakePlayers = {}
fakePlayers.PlayerRemoving = {
	Connect = function()
		return { Disconnect = function() end }
	end,
}
local owner = { Name = "SpecRunner", UserId = 90000000301, Parent = fakePlayers }
function fakePlayers:GetPlayers()
	return { owner }
end

local profile = Schema.Default()
local PDS = {
	Get = function(p)
		return if p == owner then profile else nil
	end,
	IsReady = function()
		return true
	end,
	SetSpeedMilestone = function(_, m)
		record("SetSpeedMilestone", m)
		if m > profile.SpeedMilestone then
			profile.SpeedMilestone = m
			return true
		end
		return false
	end,
	AddMilestoneSpinsOwed = function(_, d)
		profile.MilestoneSpinsOwed = math.clamp(profile.MilestoneSpinsOwed + d, 0, 5)
		record("Owed", profile.MilestoneSpinsOwed)
		return profile.MilestoneSpinsOwed
	end,
	OnSpeedGained = function()
		return function() end
	end,
}
local testPlot = Instance.new("Model")
testPlot.Name = "SpecFunPlot"
testPlot:SetAttribute(ATTR.PlotId, 99)
testPlot.Parent = fixture
local Plots = {
	PlotOf = function(p)
		return if p == owner then testPlot else nil
	end,
	OwnerOf = function(plot)
		return if plot == testPlot then owner else nil
	end,
}
local income = 0
local Econ = {
	RateFor = function()
		return income
	end,
	PayReward = function(_, amount, reason)
		record("PayReward", amount, reason)
		return true
	end,
}
local onDisco = false
local Mill = {
	OnDiscoMill = function()
		return onDisco
	end,
}
local carrying = false
local Carry = {
	IsCarrying = function()
		return carrying
	end,
}
local room = 99
local ticketOpen = true
local Wheel = {
	GrantMilestoneSpins = function(_, n, why)
		local landed = math.min(n, room)
		record("GrantMilestoneSpins", n, landed, why)
		return landed
	end,
	BeltTicketOpen = function()
		return ticketOpen
	end,
	GrantBeltTicket = function()
		record("GrantBeltTicket")
		return true, nil
	end,
}

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	end
	return game:GetService(name)
end

local outerRequire = require
local function loadWith(module, siblings)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	local env = setmetatable({
		game = fakeGame,
		script = { Name = module.Name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) })
	setfenv(chunk, env)
	return chunk()
end

local savedState, savedMode = Workspace:GetAttribute(EVENT.State), Workspace:GetAttribute(EVENT.Mode)

local function serviceBody()
	local Fun = loadWith(Server.TreadmillFunService, {
		PlayerDataService = PDS, PlotService = Plots, EconomyService = Econ,
		TreadmillService = Mill, CarryService = Carry, WheelService = Wheel,
	})
	Fun.Init()
	local told = {}
	Fun.SpecTell(function(_, payload)
		table.insert(told, payload)
	end)

	--==========================================================================
	-- 4. THE PRIZES
	--==========================================================================
	say("\n-- the prizes --")
	income = 0
	Fun.SpecSpeedGained(owner, 0, 1200, nil)
	local paid = last("PayReward")
	local spins = last("GrantMilestoneSpins")
	check(profile.SpeedMilestone == 1000, "0 -> 1,200: the mark moves to 1K", profile.SpeedMilestone)
	check(count("PayReward") == 1 and paid and paid.args[1] == SpeedMilestones.cashFor(100, 0, 1)
			+ SpeedMilestones.cashFor(500, 0, 1), "100 and 500 pay their cash together ($350 with no income)",
		paid and paid.args[1])
	check(spins and spins.args[1] == 1, "and 1K its spin ticket")
	check(#told == 1 and told[1].title == "MILESTONE! 1K Speed" and told[1].detail == "+$350 \u{00B7} +1 Spin Ticket"
		and told[1].icon == "tickets", "in ONE notice: MILESTONE! 1K Speed / +$350 · +1 Spin Ticket",
		told[1] and told[1].detail)
	table.clear(told)
	trace = {}
	Fun.SpecSpeedGained(owner, 1200, 1300, nil)
	check(count("PayReward") == 0 and #told == 0, "a gain that crosses nothing pays nothing")
	Fun.SpecSpeedGained(owner, 0, 1300, nil)
	check(count("PayReward") == 0 and count("GrantMilestoneSpins") == 0, "and nothing is ever paid twice")
	income = 30
	Fun.SpecSpeedGained(owner, 1300, 6000, nil)
	paid = last("PayReward")
	check(profile.SpeedMilestone == 5000 and paid and paid.args[1] == 1800,
		"5K with $30/s of garden: 60 s of it, $1,800 (over the $1K floor)", paid and paid.args[1])
	trace = {}
	table.clear(told)
	Fun.SpecSpeedGained(owner, 6000, 2e6, "admin")
	check(profile.SpeedMilestone == 1e6 and count("PayReward") == 0 and count("GrantMilestoneSpins") == 0 and #told == 0,
		"admin Speed to 2M: 10K .. 1M are passed with NO prize")
	Fun.SpecSpeedGained(owner, 2e6, 2.1e6, "debug")
	Fun.SpecSpeedGained(owner, 2.1e6, 1.5e7, "debug")
	check(profile.SpeedMilestone == 1e7 and count("PayReward") == 0, "and so is debug Speed")
	room = 0
	trace = {}
	Fun.SpecSpeedGained(owner, 1.5e7, 2e9, nil)
	check(profile.MilestoneSpinsOwed == 1 and profile.SpeedMilestone == 1e9,
		"a full spin balance at 1B: the ticket is OWED, not lost", profile.MilestoneSpinsOwed)
	room = 99
	trace = {}
	Fun.SpecSpeedGained(owner, 2e9, 2.1e9, nil)
	check(profile.MilestoneSpinsOwed == 0 and count("GrantMilestoneSpins") == 1, "and paid on the next gain with room")
	local funSrc = sourceOf(Server, "TreadmillFunService")
	check(not has(funSrc, "PlayerDataService.AddSpeed(") and not has(funSrc, "TreadmillService.PayReward(")
			and not has(funSrc, "OnServerEvent"),
		"the service never adds Speed and listens to no client at all")

	--==========================================================================
	-- 5. THE CATCH, ON A REAL BELT PART
	--==========================================================================
	say("\n-- the catch --")
	local mill = Instance.new("Model")
	mill.Name = "SpecFunMill"
	mill:SetAttribute(ATTR.PlotId, 99)
	mill.Parent = fixture
	local belt = Instance.new("Part")
	belt.Name = GameConfig.Plot.TreadmillName
	belt.Anchored = true
	belt.Size = Vector3.new(8, 1.4, 16)
	belt.CFrame = CFrame.new(400, 600, 400) * CFrame.Angles(0, math.rad(30), 0)
	belt.Parent = mill
	CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)
	local body = Instance.new("Model")
	body.Name = "SpecRunnerBody"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.Size = Vector3.new(2, 2, 1)
	root.Parent = body
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 2
	humanoid.Parent = body
	body.Parent = fixture
	owner.Character = body
	local function standAt(z, lift)
		root.CFrame = belt.CFrame * CFrame.new(0, belt.Size.Y * 0.5 + 3 + (lift or 0), z)
	end

	local T = 5000
	Fun.SpecClock(function()
		return T
	end)
	standAt(30)
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) == nil, "off the belt: nothing comes")
	standAt(0)
	Fun.SpecStep(T)
	T += 7.9
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) == nil, "on it: nothing in the first 8 s")
	T += 4.2
	Fun.SpecStep(T)
	local item = Fun.SpecItem(owner)
	check(item ~= nil and item.kind == "coin" or (item ~= nil and item.kind == "ticket"),
		"by 12 s, one item", item and item.kind)
	if item and item.kind == "ticket" then
		-- The roll's 1 in 8 came up: stand aside for this one and take the next.
		Fun.SpecNextKind(function()
			return "coin"
		end)
		T = item.endsAt + 1
		Fun.SpecStep(T)
		T += 12.1
		Fun.SpecStep(T)
		item = Fun.SpecItem(owner)
		Fun.SpecNextKind(nil)
	end
	local folder = Workspace:FindFirstChild(Fun.FolderName)
	local rec = folder and item and folder:FindFirstChild("B" .. tostring(item.id))
	check(rec ~= nil and rec:GetAttribute("Owner") == owner.UserId and rec:GetAttribute("Kind") == "coin"
			and typeof(rec:GetAttribute("From")) == "Vector3" and rec:GetAttribute("StartsAt") == item.startsAt,
		"its record is published for the owner's client to draw: owner, kind, path, times")
	local fromL = belt.CFrame:PointToObjectSpace(item.from)
	local toL = belt.CFrame:PointToObjectSpace(item.to)
	check(fromL.Z < 0 and toL.Z > 0 and math.abs(fromL.Y - (belt.Size.Y * 0.5 + BeltCatch.Height)) < 1e-3,
		"it comes from the console end toward the player, at jump height")
	-- When it passes the player at z = 0.
	local function passOf(it)
		return it.startsAt + (0 - fromL.Z) / (toL.Z - fromL.Z) * (it.endsAt - it.startsAt)
	end
	T = passOf(item)
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) == item, "standing still as it passes: not caught")
	standAt(0, 3)
	T += 0.05
	trace = {}
	table.clear(told)
	income = 12
	Fun.SpecStep(T)
	paid = last("PayReward")
	check(Fun.SpecItem(owner) == nil and paid and paid.args[1] == BeltCatch.coinCash(12),
		"jumping as it passes: caught, and paid 15 s of income ($180)", paid and paid.args[1])
	check(rec:GetAttribute("CaughtBy") == owner.UserId and rec:GetAttribute("Paid") == 180,
		"the record says who caught it and for what")
	check(#told == 1 and told[1].icon == "coin" and told[1].title == "SEED COIN! +$180", "SEED COIN! +$180, the coin's icon")
	standAt(0)

	-- A golden ticket, asked for; then the cap.
	Fun.SpecNextKind(function()
		return "ticket"
	end)
	T += 12.1
	Fun.SpecStep(T)
	item = Fun.SpecItem(owner)
	check(item and item.kind == "ticket", "a golden ticket comes while the window has room")
	T = passOf(item)
	standAt(0, 4)
	trace = {}
	table.clear(told)
	Fun.SpecStep(T)
	check(count("GrantBeltTicket") == 1 and count("PayReward") == 0 and told[1] and told[1].icon == "tickets",
		"caught: one free spin through WheelService, the ticket's own picture")
	standAt(0)
	ticketOpen = false
	T += 12.1
	Fun.SpecStep(T)
	item = Fun.SpecItem(owner)
	check(item and item.kind == "coin", "with the day's ticket used, even an asked-for ticket comes as a coin")

	-- A miss drifts away.
	trace = {}
	T = item.endsAt + BeltCatch.LatencySeconds + 0.1
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) == nil and count("PayReward") == 0, "never jumped: it drifts away, nothing paid")

	-- What stops it.
	Fun.SpecNextKind(nil)
	T += 12.1
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) ~= nil, "(the next one comes)")
	standAt(0, 7)
	T += 0.05
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) ~= nil, "a jump's peak (7 studs up, over the mill's own 6.5) does not withdraw it")
	standAt(0)
	carrying = true
	T += 0.05
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) == nil, "carrying a pod withdraws the item")
	T += 30
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) == nil, "and none comes while carrying")
	carrying = false
	onDisco = true
	T += 30
	Fun.SpecStep(T)
	T += 30
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) == nil, "nor on the Disco Mill")
	onDisco = false
	Workspace:SetAttribute(EVENT.State, "running")
	for _, mode in ipairs({ "tickets", "ticketdisco" }) do
		Workspace:SetAttribute(EVENT.Mode, mode)
		T += 30
		Fun.SpecStep(T)
		T += 30
		Fun.SpecStep(T)
		check(Fun.SpecItem(owner) == nil, "nor while a " .. mode .. " mini event runs")
	end
	Workspace:SetAttribute(EVENT.Mode, "disco")
	T += 30
	Fun.SpecStep(T)
	T += 30
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) ~= nil, "a disco without tickets does not stop it")
	Workspace:SetAttribute(EVENT.State, savedState)
	Workspace:SetAttribute(EVENT.Mode, savedMode)
	humanoid.Health = 0
	T += 0.05
	Fun.SpecStep(T)
	check(Fun.SpecItem(owner) == nil, "dead: withdrawn")

	-- The rules the item records the decision on.
	local ui = sourceOf(Scripts, "TreadmillFunUI")
	check(not has(ui, "FireServer") and not has(ui, "InvokeServer"),
		"the client never sends anything: a client claim has nothing to go through")
	check(BeltCatch.ticketAvailable(0, 0, 100) and not BeltCatch.ticketAvailable(100, 1, 100 + 86399)
			and BeltCatch.ticketAvailable(100, 1, 100 + 86400), "one ticket per rolling 24 h, from the first one caught")
	local gapsOk = true
	local rng = Random.new(7)
	for _ = 1, 500 do
		local g = BeltCatch.nextGap(rng)
		if g < 8 or g > 12 then
			gapsOk = false
		end
	end
	check(gapsOk, "every gap between items is 8-12 s")
	local tickets = 0
	rng = Random.new(11)
	for _ = 1, 8000 do
		if BeltCatch.rollKind(rng, true) == "ticket" then
			tickets += 1
		end
	end
	check(tickets > 800 and tickets < 1200, "about 1 in 8 is a golden ticket when one may come", tickets)
	check(BeltCatch.rollKind(rng, false) == "coin", "and none when it may not")
	check(BeltCatch.coinCash(0) == 10 and BeltCatch.coinCash(100) == 1500, "a coin: 15 s of income, never under $10")
	local wheelSrc = sourceOf(Server, "WheelService")
	local grant = string.match(wheelSrc, "function WheelService.GrantBeltTicket.-\nend") or ""
	check(has(grant, "q.BeltTicketCount = count + 1") and not has(grant, "WheelDay"),
		"the belt's window is its own: the obby's daily allowance is not read or written")
	Fun.Init()
end

local ok, err = pcall(serviceBody)
if not ok then
	fail += 1
	say("  FAIL  the service half threw  <- " .. tostring(err))
end
Workspace:SetAttribute(EVENT.State, savedState)
Workspace:SetAttribute(EVENT.Mode, savedMode)
local folder = Workspace:FindFirstChild("BeltItems")
if folder then
	folder:Destroy()
end
for _, d in ipairs(fixture:GetDescendants()) do
	if CollectionService:HasTag(d, GameConfig.Tags.Treadmill) then
		CollectionService:RemoveTag(d, GameConfig.Tags.Treadmill)
	end
end
fixture:Destroy()

--==============================================================================
-- 6. THE PATH CLEARS EVERY MILL ON EVERY PLOT
--==============================================================================
say("\n-- the path --")
do
	local MAP = GameConfig.Map
	local sweep = Instance.new("Folder")
	sweep.Name = "TreadmillFunSpecSweep"
	sweep.Archivable = false
	sweep.Parent = Workspace
	local n = GameConfig.MaxPlots
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(GameConfig.StartingPlotTier))
	local gap = math.rad(MAP.RoadGapDegrees)
	local stepA = (math.pi * 2 - gap) / n
	local first = math.pi + gap * 0.5
	local probe = Instance.new("Part")
	probe.Shape = Enum.PartType.Ball
	probe.Anchored = true
	probe.CanCollide = false
	probe.CanTouch = false
	probe.Transparency = 1
	probe.Size = Vector3.one * BeltCatch.ClearRadius * 2
	local hits, samples, mills = {}, 0, 0
	local sweepOk, sweepErr = pcall(function()
		for id = 1, n do
			local angle = first + (id - 0.5) * stepA
			local r = MAP.PlotRingInner + startDepth * 0.5
			local pos = Vector3.new(math.sin(angle) * r, MAP.GroundY, math.cos(angle) * r)
			local centre = CFrame.lookAt(pos, Vector3.new(0, MAP.GroundY, 0))
			local plot = Instance.new("Model")
			plot.Name = "SweepPlot" .. id
			plot:SetAttribute(ATTR.PlotId, id)
			plot:SetAttribute("PlotCF", centre)
			plot:SetAttribute("Depth", startDepth)
			plot:SetAttribute("Level", GameConfig.StartingPlotTier)
			plot.Parent = sweep
			MapService.ResizePlot(plot, #GameConfig.PlotTiers)
			local gate = centre * CFrame.new(0, 0, -startDepth * 0.5)
			local cf = GameConfig.millCFrameFor(gate, id)
			local beside = GameConfig.millStandsBeside(id)
			for tier = 1, #GameConfig.Mill.Tiers do
				local model, belt = MillModel.Build(tier, cf, sweep)
				if beside then
					MillModel.Soften(model, GameConfig.millGateFor(cf, id), tier)
				end
				mills += 1
				local params = OverlapParams.new()
				params.FilterType = Enum.RaycastFilterType.Include
				params.FilterDescendantsInstances = { model, plot }
				params.RespectCanCollide = false
				for _, lateral in ipairs({ -10, 0, 10 }) do
					local from, to = BeltCatch.path(belt.CFrame, belt.Size, lateral)
					for k = 0, 24 do
						local p = probe:Clone()
						p.Position = from:Lerp(to, k / 24)
						p.Parent = sweep
						for _, h in ipairs(Workspace:GetPartsInPart(p, params)) do
							if h ~= belt then
								hits[string.format("plot %d tier %d %s", id, tier, h.Name)] = true
							end
						end
						p:Destroy()
						samples += 1
					end
				end
				model:Destroy()
			end
			plot:Destroy()
		end
	end)
	sweep:Destroy()
	local list = {}
	for k in pairs(hits) do
		table.insert(list, k)
	end
	table.sort(list)
	check(sweepOk, "the sweep ran", sweepErr)
	check(mills == 6 * 14 and #list == 0,
		string.format("the item's path clears all 14 tiers on all 6 plots (Level 7 plots, plot 6's softened), %d samples",
			samples), table.concat(list, "; "))
end

--==============================================================================
-- 7. WHAT DID NOT MOVE, AND THE ICONS
--==============================================================================
say("\n-- unchanged --")
do
	local mill = sourceOf(Server, "TreadmillService")
	-- Sprout Dash (2026-10-08) adds its own boost to the chest's -- the owner's
	-- choice -- and treadmill fun still adds nothing to the rate.
	check(has(mill, "local paid = rate * training * discoFactor * dt")
		and has(mill, "local training = BonusChestService.Multiplier(player, \"training\")"),
		"the belt still pays its one rate, times its boosts (the chest's, and Sprout Dash's added): treadmill fun adds none")
	local rates = { 20, 100, 1000, 8000, 50000, 300000, 2e6, 1.2e7, 7e7, 4e8, 2.5e9, 1.5e10, 8e10, 4.5e11 }
	local same = true
	for tier, rate in ipairs(rates) do
		if GameConfig.Mill.Tiers[tier].speed ~= rate then
			same = false
		end
	end
	check(same, "the fourteen tier rates are 20 .. 450B, as before")
	local SizedIcon = require(Shared:WaitForChild("SizedIcon"))
	local PLAIN, SMALL = "rbxassetid://99714577637458", "rbxassetid://114664524232030"
	check(GameConfig.SourceIcons.speed == PLAIN and GameConfig.SmallIcons[PLAIN] == SMALL
			and GameConfig.SourceIcons.training == "rbxassetid://113941145748388",
		"Speed is the owner's transparent plain shoe (small version 114664524232030); the +25% training boost keeps the boosted shoe")
	check(SizedIcon.at(PLAIN, 40) == SMALL and SizedIcon.at(PLAIN, 24) == SMALL and SizedIcon.at(PLAIN, 40.5) == PLAIN
			and SizedIcon.at(PLAIN, 0) == PLAIN and SizedIcon.at(PLAIN, nil) == PLAIN and SizedIcon.at(SMALL, 90) == PLAIN,
		"the small version wherever the shoe draws at 40 px or less, the plain one above (and when the size is unknown)")
	check(SizedIcon.at(GameConfig.SourceIcons.training, 20) == GameConfig.SourceIcons.training
			and SizedIcon.at(GameConfig.SourceIcons.coin, 20) == GameConfig.SourceIcons.coin,
		"a picture with no small version is never swapped")
	check(ShopCatalog.SpeedIcon == GameConfig.SourceIcons.speed and has(sourceOf(Shared, "WheelDraw"),
		"local SPEED_ICON = GameConfig.SourceIcons.speed"), "the Shop and the wheel's Speed prizes show Speed")
	check(has(sourceOf(Shared, "WheelDraw"), "shoe.Image = GameConfig.SourceIcons.training"),
		"the wheel's +25% Training slice shows the boosted shoe (the dumbbell under it until it loads)")
	-- Every Speed display draws it, at its size.
	local followers = {
		{ Shared, "MenuKit", "SizedIcon.follow(pic)" },
		{ Shared, "WheelDraw", "SizedIcon.follow(image)" },
		{ Shared, "StatusText", "image.Image = SizedIcon.at(picture, size)" },
		{ Scripts, "CashUI", "shoePicture.Image = SizedIcon.at(GameConfig.SourceIcons.speed, PICTURE * style.ShoeScale)" },
		{ Scripts, "SpeedFX", "picture.Image = SizedIcon.at(GameConfig.SourceIcons.speed, 20)" },
		{ Scripts, "TreadmillFunUI", "popShoe.Image = SizedIcon.at(SpeedMilestones.Art.Shoe, SHOE_PX.Pop * scale())" },
		{ Scripts, "TreadmillFunUI", "SizedIcon.at(SpeedMilestones.Art.Shoe, SHOE_PX.Bar * k)" },
		{ Scripts, "TreadmillFunUI", "badgeShoe.Image = SizedIcon.at(SpeedMilestones.Art.Shoe, SHOE_PX.Badge)" },
	}
	local missing = {}
	for _, f in ipairs(followers) do
		if not has(sourceOf(f[1], f[2]), f[3]) then
			table.insert(missing, f[2])
		end
	end
	check(#missing == 0 and SpeedMilestones.Art.Shoe == GameConfig.SourceIcons.speed,
		"the HUD, the Shop and Index, the wheel, notices, SpeedFX's +N and the pop, bar and badge all draw the shoe at its size",
		table.concat(missing, ","))
	local cash = sourceOf(Scripts, "CashUI")
	check(has(cash, "shoe.Size = UDim2.fromOffset(50, 38)") and has(cash, "drawn.Visible = false"),
		"the HUD's shoe is the picture in the same 50 x 38 box (no HUD rect moves), the frame sneaker under it until it loads")
	-- The two shoes uploaded on black, and the old winged shoe: mentioned in
	-- comments, drawn nowhere.
	local drawnAt, oldAt = {}, {}
	for _, root in ipairs({ ReplicatedStorage, StarterPlayer, ServerScriptService }) do
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then
				local src = sourceOf(d.Parent, d.Name)
				for line in string.gmatch(src, "[^\n]+") do
					if not string.match(line, "^%s*%-%-") then
						if has(line, "87020355715502") or has(line, "137016623960738") then
							table.insert(drawnAt, d.Name)
						end
						if has(line, "96656510808947") then
							table.insert(oldAt, d.Name)
						end
					end
				end
			end
		end
	end
	check(#drawnAt == 0, "the two shoes uploaded on black are drawn nowhere -- never a black square",
		table.concat(drawnAt, ","))
	check(#oldAt == 0, "the old winged shoe 96656510808947 is no longer used anywhere", table.concat(oldAt, ","))
end

say(string.format("\nTreadmillFunSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
