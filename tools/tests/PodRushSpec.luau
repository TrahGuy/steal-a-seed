--!nocheck
--==============================================================================
-- Steal a Seed :: PodRushSpec (2026-10-09; KB/POD-RUSH-PLAN.md)
--
-- POD RUSH, in Edit:
--   1. the config: the mode, the levels and their rewards, the art and its crop
--   2. the rules (Shared/PodRush): the levels, what counts (nest thefts only,
--      inside the window plus the grace), the owed pods, the words, the ring
--   3. the server (the real PodRushService, every hook stood in): a rush
--      begins; pods count; each level pays once -- the spins (any that do not
--      fit owed), the boost, the GOLD pod from the top biome (owed while the
--      Bag is full, then given, oldest first); GOLD told to everyone else; the
--      close and the grace; the end cards and PodRushEnded once per player; a
--      rejoin keeps the count; a late join; a new rush starts again
--   4. the nests (the real NestService on a spec record): a taken slot grows
--      back RegrowSeconds later in a rush, never outside one, never at night
--      or on a weather event's nest; no rage past one stack in a rush
--   5. dusk held (the real WorldCycleService on stand-ins)
--   6. the tracker and the end card fit every listed screen
--   7. the wiring: the console, the shared record, the boost icon, the notice
--      crop, the saved row, analytics, the music slots, the carry, the client
--
-- Simulated user ids from 90,000,000,000: never a real account.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local PodRush = require(Shared:WaitForChild("PodRush"))

local RUSH = GameConfig.PodRush
local A = RUSH.Attributes
local EV = RUSH.Events
local WORDS = RUSH.Words
local MINI = GameConfig.MiniEvent
local V = Vector3.new

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
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
local function sourceOf(root, name)
	local found = root and root:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function bodyOf(src, header)
	local from = src:find(header, 1, true)
	return if from then src:sub(from, (src:find("\nend\n", from, true) or #src)) else ""
end

local fixture = Instance.new("Folder")
fixture.Name = "PodRushSpecFixture"
fixture.Parent = ServerStorage

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the config --")
	--==========================================================================
	local mode = MINI.Modes.podrush
	check(mode ~= nil and mode.Name == "POD RUSH" and mode.PodRush == true and mode.Tickets == false
			and mode.Disco == false and mode.Mill == false and mode.Seconds == 300 and mode.SpeedFactor == nil,
		"POD RUSH is the fifth mini event mode: no disco, tickets or mill; five minutes")
	check(mode.Announce.Title == "POD RUSH!"
			and mode.Announce.Detail == "Steal and bank as many pods as you can in 5 minutes!"
			and mode.Announce.Icon == "podrush",
		"its announcement is the plan's words, with the rush icon")
	local L1, L2, L3 = RUSH.Levels[1], RUSH.Levels[2], RUSH.Levels[3]
	check(#RUSH.Levels == 3 and L1.Pods == 3 and L2.Pods == 7 and L3.Pods == 12
			and L1.Spins == 1 and L1.Boost == nil and L1.PodTier == nil
			and L2.Spins == 3 and L2.Boost == "training" and L2.PodTier == nil
			and L3.Spins == 5 and L3.PodTier == 6 and SeedData.TierName(6) == "Titan",
		"the owner's levels: 3 / 7 / 12; 1 ticket; 3 tickets + training; 5 tickets + a Titan pod")
	check(RUSH.RegrowSeconds == 15 and RUSH.GraceSeconds == 20 and RUSH.Mode == "podrush"
			and RUSH.DuskMarginSeconds > 0 and RUSH.MaxOwed >= 2,
		"nests regrow in 15 s, a carried pod has 20 s of grace, dusk waits a little past it")
	local ART = RUSH.Art
	check(ART.Icon == "rbxassetid://108173602941410" and ART.Bronze == "rbxassetid://106320803448209"
			and ART.Silver == "rbxassetid://108448116105933" and ART.Gold == "rbxassetid://100048210150003"
			and ART.CropOffset == Vector2.new(41, 41) and ART.CropSize == Vector2.new(430, 430),
		"the owner's four uploads, one shared crop (41,41)+430")
	check(GameConfig.SourceIcons.podrush == ART.Icon and GameConfig.SourceIconCrops.podrush.Offset == ART.CropOffset
			and GameConfig.SourceIconCrops.podrush.Size == ART.CropSize,
		"the notices and the boost icon draw the rush icon by its crop")
	check(GameConfig.bonusChestReward("training") ~= nil, "the SILVER boost is the chest's own training boost")

	--==========================================================================
	say("-- 2. the rules --")
	--==========================================================================
	local levels = {}
	for _, n in ipairs({ 0, 2, 3, 6, 7, 11, 12, 40 }) do
		table.insert(levels, PodRush.levelFor(n))
	end
	check(table.concat(levels, ",") == "0,0,1,1,2,2,3,3", "the level a count reaches", table.concat(levels, ","))
	local lv, need = PodRush.nextLevel(5)
	local top, none = PodRush.nextLevel(12)
	check(lv == 2 and need == 2 and top == nil and none == 0, "the next level and what it needs")
	check(table.concat(PodRush.toPay(0, 1), ",") == "1" and table.concat(PodRush.toPay(1, 3), ",") == "2,3"
			and #PodRush.toPay(3, 3) == 0 and #PodRush.toPay(2, 1) == 0,
		"each level is owed once: only those above what was paid")
	local all = PodRush.rewardsUpTo(3)
	check(all.spins == 9 and all.boost == "training" and all.podTier == 6 and PodRush.rewardsUpTo(0).spins == 0,
		"GOLD has paid nine tickets, the boost and the pod in all")
	local W = { startedAt = 1000, endsAt = 1300 }
	check(PodRush.counts(W, 1005, 1010) and not PodRush.counts(W, nil, 1010) and not PodRush.counts(W, 999, 1010)
			and not PodRush.counts(W, 1301, 1310),
		"a nest theft inside the window counts; a re-pick, one from before or one after never does")
	check(PodRush.counts(W, 1299, 1319) and not PodRush.counts(W, 1299, 1321),
		"a pod taken in time has the grace to be banked, and not a second more")
	local closed = { startedAt = 1000, endsAt = 1300, closedAt = 1200 }
	check(PodRush.counts(closed, 1199, 1219) and not PodRush.counts(closed, 1201, 1205)
			and not PodRush.counts(closed, 1199, 1221),
		"an END closes the window early: the grace runs from it")
	check(table.concat(PodRush.owedList("a,b,,c"), "|") == "a|b|c" and PodRush.owedString({ "a", "b" }) == "a,b"
			and #PodRush.owedList(string.rep("x,", 20)) == RUSH.MaxOwed and PodRush.owedString({}) == ""
			and #PodRush.owedList(nil) == 0,
		"owed pods: a short list, oldest first, never past MaxOwed")
	check(PodRush.clock(192) == "3:12" and PodRush.clock(-4) == "0:00" and PodRush.clock(0.2) == "0:01",
		"the clock reads m:ss")
	check(PodRush.bankedLine(5) == "5 banked" and PodRush.nextLine(5) == "2 more for SILVER"
			and PodRush.nextLine(0) == "3 more for BRONZE" and PodRush.nextLine(12) == WORDS.Top,
		"the tracker's words")
	check(PodRush.overLine(9, 2) == "9 pods \u{00B7} SILVER!" and PodRush.overLine(1, 0) == "1 pod \u{00B7} no level",
		"the end card's line", PodRush.overLine(9, 2))
	check(PodRush.serverLine("Pat") == "Pat hit GOLD in the Pod Rush!", "the line everyone else reads")
	local r1 = PodRush.rewardLines({ spins = 3, boost = "training" })
	local r2 = PodRush.rewardLines({ spins = 1 })
	local r3 = PodRush.rewardLines({ spins = 5, podTier = 6 }, "Starbloom")
	check(table.concat(r1, "|") == "+3 Spin Tickets|+25% training for 2 min" and table.concat(r2, "|") == "+1 Spin Ticket"
			and table.concat(r3, "|") == "+5 Spin Tickets|a Titan Starbloom pod",
		"what a level paid, said plainly", table.concat(r1, "|") .. " / " .. table.concat(r3, "|"))
	check(PodRush.medal(1) == ART.Bronze and PodRush.medal(2) == ART.Silver and PodRush.medal(3) == ART.Gold
			and PodRush.medal(0) == "" and PodRush.levelId(0) == "none" and PodRush.levelId(3) == "gold",
		"each level wears its medal")
	local centre = V(10, 0, -50)
	local ring = PodRush.ring(centre)
	local okRing = #ring == RUSH.Ring.Segments
	for _, seg in ipairs(ring) do
		local p = seg.cframe.Position
		local flat = V(p.X - centre.X, 0, p.Z - centre.Z)
		local radial = flat.Unit
		if math.abs(flat.Magnitude - RUSH.Ring.Radius) > 1e-3 or math.abs(p.Y - (RUSH.Ring.Thickness / 2 + 0.05)) > 1e-3
			or math.abs(seg.cframe.RightVector:Dot(radial)) > 1e-3 or seg.size.Z ~= RUSH.Ring.Width then
			okRing = false
		end
	end
	check(okRing, "the ring: its bars on the pods' own ring, just over the ground, each a chord along it")

	--==========================================================================
	say("-- 3. the server --")
	--==========================================================================
	local PodRushService = require(Server:WaitForChild("PodRushService"))
	local H = PodRushService.Hooks
	local saved = {}
	for k, v in pairs(H) do
		saved[k] = v
	end
	local served, serveErr = pcall(function()
		local clock = 1000
		local mini = {}
		local sent = {}
		local untilAt: any = "unset"
		local rushOn: any = nil
		local profiles = {}
		local spins, owed, boosts, pods, metrics = {}, {}, {}, {}, {}
		local landedFor = {}
		local podRoom = false
		local carryingAt = {}
		local roster = {}
		local function standIn(id, name)
			local p = { UserId = id, Name = name, DisplayName = name, attrs = {} }
			function p:SetAttribute(k, v)
				self.attrs[k] = v
			end
			function p:GetAttribute(k)
				return self.attrs[k]
			end
			return p
		end
		local function freshRow()
			return { Id = "", Count = 0, Paid = 0, Top = 0, PodOwed = "" }
		end
		H.now = function()
			return clock
		end
		H.players = function()
			return roster
		end
		H.state = function()
			return mini
		end
		H.send = function(p, action, payload)
			table.insert(sent, { to = p, action = action, payload = payload })
		end
		H.setUntil = function(at)
			untilAt = at
		end
		H.setRush = function(on)
			rushOn = on
		end
		H.profile = function(p)
			return profiles[p]
		end
		H.update = function(p, change)
			local prof = profiles[p]
			if not prof then
				return false
			end
			return change(prof) == true
		end
		H.spins = function(p, n, why)
			table.insert(spins, { p = p, n = n, why = why })
			local cap = landedFor[p]
			return if cap then math.min(cap, n) else n
		end
		H.owe = function(p, n)
			table.insert(owed, { p = p, n = n })
		end
		H.boost = function(p, id)
			table.insert(boosts, { p = p, id = id })
			return true
		end
		H.givePod = function(p, speciesId, tier)
			table.insert(pods, { p = p, species = speciesId, tier = tier, given = podRoom })
			return podRoom
		end
		H.carrying = function(p)
			return carryingAt[p]
		end
		H.metric = function(p, count, level)
			table.insert(metrics, { p = p, count = count, level = level })
		end
		H.random = function()
			return Random.new(7)
		end
		local function sentTo(p, action)
			local list = {}
			for _, s in ipairs(sent) do
				if s.to == p and s.action == action then
					table.insert(list, s.payload)
				end
			end
			return list
		end
		local function countOf(list, p)
			local n = 0
			for _, row in ipairs(list) do
				if row.p == p then
					n += 1
				end
			end
			return n
		end
		local speciesCache = {}
		local function speciesOf(biomeId)
			speciesCache[biomeId] = speciesCache[biomeId] or SeedData.Roll(biomeId, Random.new(3))
			return speciesCache[biomeId]
		end
		local function bank(p, stolenAt, biomeId)
			PodRushService.Banked(p, { species = speciesOf(biomeId or "greenhollow"), tier = 2, fromNest = "Nest_spec",
				stolenAt = stolenAt })
		end
		local function biomeOfPod(row)
			local sp = row and SeedData.Get(row.species)
			return sp and sp.Biome
		end

		PodRushService.Reset()
		local pat = standIn(90000000001, "Pat")
		local sam = standIn(90000000002, "Sam")
		roster = { pat, sam }
		profiles[pat] = { PodRush = freshRow() }
		profiles[sam] = { PodRush = { Id = "oldrush", Count = 9, Paid = 2, Top = 3, PodOwed = "dustbowl" } }

		PodRushService.Step(clock)
		bank(pat, clock - 1)
		mini = { state = "running", mode = "ticketdisco", id = "discoAAAA1111", startedAt = 990, endsAt = 1080 }
		PodRushService.Step(clock)
		check(PodRushService.Current() == nil and rushOn == nil and untilAt == "unset" and #sent == 0
				and profiles[pat].PodRush.Count == 0,
			"no rush, or another mini event: nothing runs and a bank counts nothing")

		-- BEGIN
		local ID = "rushAAAA11112222"
		mini = { state = "running", mode = "podrush", id = ID, startedAt = 1000, endsAt = 1300 }
		clock = 1000.5
		PodRushService.Step(clock)
		local cur = PodRushService.Current()
		check(cur ~= nil and cur.id == ID and rushOn == true and untilAt == 1300 + RUSH.GraceSeconds,
			"a rush begins: the nests regrow, dusk is held to its end and the grace")
		check(pat.attrs[A.Id] == ID and pat.attrs[A.Count] == 0 and pat.attrs[A.Level] == 0
				and sam.attrs[A.Id] == ID and sam.attrs[A.Count] == 0,
			"each player's numbers are published for this rush")
		local samRow = profiles[sam].PodRush
		check(samRow.Id == ID and samRow.Count == 0 and samRow.Paid == 0 and samRow.Top == 0
				and samRow.PodOwed == "dustbowl",
			"another rush's saved row starts again, and a GOLD pod still owed stays owed")
		check(countOf(pods, sam) == 1 and pods[1].given == false,
			"the owed pod was tried, and stays owed while the Bag is full")

		-- COUNTING
		clock = 1010
		bank(pat, 1005)
		local c1 = sentTo(pat, EV.Counted)[1]
		check(profiles[pat].PodRush.Count == 1 and pat.attrs[A.Count] == 1 and c1 and c1.count == 1 and c1.level == 0
				and c1.levelUp == nil and c1.id == ID,
			"a pod taken from a nest during the rush and banked counts one: saved, published, its +1 sent")
		bank(pat, nil)
		bank(pat, 999)
		check(profiles[pat].PodRush.Count == 1 and #sentTo(pat, EV.Counted) == 1,
			"a pod picked back up after a drop never counts, nor one taken before the rush")
		bank(pat, 1011)
		bank(pat, 1012)
		local c3 = sentTo(pat, EV.Counted)[3]
		check(profiles[pat].PodRush.Count == 3 and pat.attrs[A.Level] == 1 and profiles[pat].PodRush.Paid == 1
				and countOf(spins, pat) == 1 and spins[1].n == 1 and c3.levelUp and c3.levelUp.level == 1
				and c3.levelUp.spins == 1 and c3.levelUp.boost == false,
			"BRONZE at 3: one Spin Ticket, the level saved as paid, the pop sent")
		for i = 4, 7 do
			bank(pat, 1012 + i)
		end
		local c7 = sentTo(pat, EV.Counted)[7]
		check(profiles[pat].PodRush.Count == 7 and countOf(spins, pat) == 2 and spins[2].n == 3
				and countOf(boosts, pat) == 1 and boosts[1].id == "training" and c7.levelUp and c7.levelUp.level == 2
				and c7.levelUp.boost == true,
			"SILVER at 7: three tickets and the training boost")
		bank(pat, 1030, "starbloom")
		for i = 9, 11 do
			bank(pat, 1030 + i)
		end
		podRoom = true
		bank(pat, 1045)
		local starbloom = BiomeData.ById.starbloom
		local c12 = sentTo(pat, EV.Counted)[12]
		local gave = pods[#pods]
		check(profiles[pat].PodRush.Count == 12 and profiles[pat].PodRush.Top == starbloom.Order
				and countOf(spins, pat) == 3 and spins[3].n == 5 and gave.p == pat and gave.tier == 6 and gave.given
				and biomeOfPod(gave) == "starbloom",
			"GOLD at 12: five tickets and a Titan pod from the highest biome banked from (Starbloom)")
		check(c12.levelUp and c12.levelUp.level == 3 and c12.levelUp.pod == starbloom.DisplayName
				and c12.levelUp.podOwed == false,
			"the GOLD pop names the pod")
		local lines = sentTo(sam, "ServerNotice")
		local goldLine = lines[#lines]
		check(goldLine and goldLine.title == "Pat hit GOLD in the Pod Rush!" and goldLine.icon == "podrush"
				and goldLine.quiet == true and #sentTo(pat, "ServerNotice") == 0,
			"everyone else here reads one quiet line; the GOLD player does not")
		bank(pat, 1046)
		local c13 = sentTo(pat, EV.Counted)[13]
		check(profiles[pat].PodRush.Count == 13 and countOf(spins, pat) == 3 and countOf(boosts, pat) == 1
				and countOf(pods, pat) == 1 and c13.levelUp == nil and pat.attrs[A.Level] == 3,
			"past GOLD it still counts, and pays nothing twice")

		-- Spins with no room are owed; GOLD pods with no room are owed, then given oldest first.
		landedFor[sam] = 0
		podRoom = false
		for i = 1, 12 do
			bank(sam, 1050 + i)
		end
		check(countOf(owed, sam) == 3 and owed[1].n == 1 and owed[2].n == 3 and owed[3].n == 5,
			"spins that do not fit on the balance are owed, every one")
		check(profiles[sam].PodRush.PodOwed == "dustbowl,greenhollow"
				and sentTo(sam, EV.Counted)[12].levelUp.podOwed == true,
			"a GOLD pod with no room in the Bag is owed after the one still owed, and the pop says so",
			profiles[sam].PodRush.PodOwed)
		podRoom = true
		PodRushService.Step(1016)
		local given = sentTo(sam, "ServerNotice")
		check(profiles[sam].PodRush.PodOwed == "greenhollow" and pods[#pods].p == sam and pods[#pods].given
				and biomeOfPod(pods[#pods]) == "dustbowl" and given[#given]
				and given[#given].title == string.format(WORDS.PodGiven, BiomeData.ById.dustbowl.DisplayName),
			"once there is room the oldest is given first, and said")
		PodRushService.Step(1019)
		local tries = #pods
		PodRushService.Step(1022)
		given = sentTo(sam, "ServerNotice")
		check(tries == #pods - 1 and profiles[sam].PodRush.PodOwed == "" and biomeOfPod(pods[#pods]) == "greenhollow"
				and given[#given].title == string.format(WORDS.PodGiven, BiomeData.ById.greenhollow.DisplayName),
			"then the next, no sooner than five seconds on")

		-- A REJOIN, A LATE JOIN
		local pat2 = standIn(90000000001, "Pat")
		profiles[pat2] = profiles[pat]
		local lee = standIn(90000000003, "Lee")
		roster = { pat2, sam, lee }
		clock = 1100
		PodRushService.Step(clock)
		check(pat2.attrs[A.Id] == ID and pat2.attrs[A.Count] == 13 and pat2.attrs[A.Level] == 3,
			"a rejoin -- any server -- meets the saved count and level")
		check(lee.attrs[A.Id] == nil, "a player whose profile has not arrived is not published yet")
		profiles[lee] = { PodRush = freshRow() }
		PodRushService.Step(clock + 0.25)
		check(lee.attrs[A.Id] == ID and lee.attrs[A.Count] == 0, "and is, the moment it has: a late join starts at 0")
		bank(pat2, 1101)
		check(profiles[pat2].PodRush.Count == 14 and countOf(spins, pat2) == 0 and countOf(pods, pat2) == 0,
			"after a rejoin nothing is paid again")

		-- CLOSE (an END), THE GRACE, FINISH
		local kim = standIn(90000000004, "Kim")
		profiles[kim] = { PodRush = freshRow() }
		roster = { pat2, sam, lee, kim }
		PodRushService.Step(1150)
		carryingAt[sam] = 1150
		carryingAt[kim] = 1100
		PodRushService.Step(1150.25)
		check(sam.attrs[A.Carrying] == true and pat2.attrs[A.Carrying] == nil,
			"a pod in the arms that would count is marked on its carrier")
		mini = { state = "ending", mode = "podrush", id = ID, startedAt = 1000, endsAt = 1300, endingAt = 1200 }
		clock = 1200.3
		PodRushService.Step(clock)
		cur = PodRushService.Current()
		check(cur and cur.closedAt == 1200 and cur.graceUntil == 1200 + RUSH.GraceSeconds and rushOn == false
				and untilAt == 1220,
			"an END closes it: the nests stop regrowing, dusk is held for the grace only")
		local overPat = sentTo(pat2, EV.Over)[1]
		local overLee = sentTo(lee, EV.Over)[1]
		check(overPat and overPat.count == 14 and overPat.level == 3 and overPat.spins == 9 and overPat.boost == true
				and overPat.pod == starbloom.DisplayName and overPat.podOwed == false and overLee and overLee.count == 0
				and overLee.level == 0,
			"empty hands: the end card now, with the pods, the level and everything it paid")
		check(#sentTo(sam, EV.Over) == 0 and #sentTo(kim, EV.Over) == 0 and sam.attrs[A.Carrying] == true,
			"a pod still in the arms waits for the grace: BANK IT!")
		clock = 1206
		bank(sam, 1205)
		check(profiles[sam].PodRush.Count == 12, "a pod taken after the close never counts")
		carryingAt[sam] = nil
		clock = 1210
		bank(sam, 1150)
		local overSam = sentTo(sam, EV.Over)
		check(profiles[sam].PodRush.Count == 13 and #overSam == 1 and overSam[1].count == 13 and sam.attrs[A.Carrying] == nil,
			"banked inside the grace it counts, and that player's end card goes at once")
		PodRushService.Step(1219)
		check(#sentTo(kim, EV.Over) == 0, "the grace runs to its end")
		PodRushService.Step(1220.5)
		check(#sentTo(kim, EV.Over) == 1 and PodRushService.Current() == nil and untilAt == nil and rushOn == false
				and pat2.attrs[A.Id] == nil and kim.attrs[A.Carrying] == nil,
			"the grace over: the rest get their end card, dusk is let go, the numbers cleared")
		local onceEach = true
		for _, p in ipairs({ pat2, sam, lee, kim }) do
			if #sentTo(p, EV.Over) ~= 1 or countOf(metrics, p) ~= 1 then
				onceEach = false
			end
		end
		local metricPat
		for _, m in ipairs(metrics) do
			if m.p == pat2 then
				metricPat = m
			end
		end
		check(onceEach and metricPat and metricPat.count == 14 and metricPat.level == "gold",
			"one end card and one PodRushEnded per player: the count and the level's word")

		-- A NEW RUSH, AND ONE WHOSE ATTRIBUTES SIMPLY GO
		local ID2 = "rushBBBB33334444"
		mini = { state = "running", mode = "podrush", id = ID2, startedAt = 2000, endsAt = 2300 }
		clock = 2000.2
		PodRushService.Step(clock)
		check(profiles[pat2].PodRush.Id == ID2 and profiles[pat2].PodRush.Count == 0 and profiles[pat2].PodRush.Paid == 0
				and pat2.attrs[A.Id] == ID2,
			"a new rush starts every row again")
		mini = {}
		clock = 2100
		PodRushService.Step(clock)
		cur = PodRushService.Current()
		check(cur and cur.closedAt == 2100 and rushOn == false, "a rush whose attributes vanish is closed at once")
		PodRushService.Step(2100 + RUSH.GraceSeconds + 1)
		check(PodRushService.Current() == nil, "and finished after the grace")
	end)
	for k, v in pairs(saved) do
		H[k] = v
	end
	PodRushService.Reset()
	check(served, "the server's checks ran to the end", serveErr)

	--==========================================================================
	say("-- 4. the nests --")
	--==========================================================================
	local NestService = require(Server:WaitForChild("NestService"))
	local HOME = V(38, 0, -715)
	local function body(name, at)
		local model = Instance.new("Model")
		model.Name = name
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Anchored = true
		root.Position = at
		root.Parent = model
		Instance.new("Humanoid").Parent = model
		model.Parent = fixture
		return model
	end
	local thiefA = { Name = "SpecA", UserId = 90000000011, Parent = Players, Character = body("SpecA", HOME + V(0, 3, 60)) }
	local thiefB = { Name = "SpecB", UserId = 90000000012, Parent = Players, Character = body("SpecB", HOME + V(0, 3, 30)) }
	local guardian = Instance.new("Model")
	guardian.Name = "SpecGuardian"
	guardian.Parent = fixture
	local groot = Instance.new("Part")
	groot.Name = "HumanoidRootPart"
	groot.Anchored = true
	groot.Position = HOME + V(0, 3, 0)
	groot.Parent = guardian
	local nest = {
		id = "Nest_spec_podrush", biome = BiomeData.ById.greenhollow, origin = HOME, homeCFrame = CFrame.new(HOME),
		parent = guardian, root = groot, folder = fixture,
		slots = { CFrame.new(HOME + V(16, 0, 0)), CFrame.new(HOME + V(-16, 0, 0)), CFrame.new(HOME + V(0, 0, 16)) },
		pods = {},
		humanoid = { WalkSpeed = 0, MoveTo = function() end },
		state = "chasing", target = thiefA, stateUntil = 0, busy = false, rage = 0, calmSince = 0,
		chaseSince = os.clock(), haul = nil, sample = nil, thieves = {}, marked = {},
	}
	local function fakePod(i)
		local m = Instance.new("Model")
		m.Name = "SpecPod" .. i
		m.Parent = fixture
		nest.pods[i] = m
	end
	for i = 1, 3 do
		fakePod(i)
	end
	local phaseAttr = GameConfig.Attributes.WorldPhase
	local phaseBefore = Workspace:GetAttribute(phaseAttr)
	local nests, nestErr = pcall(function()
		NestService.SpecStealDone(function()
			return true
		end)
		NestService.SetRush(true)
		check(NestService.RushOn() == true and NestService.SpecTakeSlot(nest, 1, thiefB) == true and nest.pods[1] == nil,
			"in a rush a taken slot is empty at once")
		local due = nest.regrowAt and nest.regrowAt[1]
		check(due ~= nil and math.abs(due - (os.clock() + RUSH.RegrowSeconds)) < 0.5,
			"and is due back RegrowSeconds later", due)
		nest.state = "asleep"
		NestService.SpecStep(nest, due - 1)
		check(nest.pods[1] == nil, "not a moment before")
		NestService.SpecStep(nest, due + 0.1)
		local pod = nest.pods[1]
		check(pod ~= nil and pod.Parent == fixture and pod:GetAttribute("NestId") == nest.id
				and pod:GetAttribute("SlotIndex") == 1 and CollectionService:HasTag(pod, GameConfig.Tags.SeedPod)
				and nest.regrowAt[1] == nil,
			"on time: a normal pod of the nest's own roll, takeable, in its slot",
			string.format("pod %s parent %s nest %s slot %s tag %s due %s phase %s", tostring(pod),
				tostring(pod and pod.Parent), tostring(pod and pod:GetAttribute("NestId")),
				tostring(pod and pod:GetAttribute("SlotIndex")),
				tostring(pod and CollectionService:HasTag(pod, GameConfig.Tags.SeedPod)), tostring(nest.regrowAt[1]),
				tostring(Workspace:GetAttribute(phaseAttr))))
		nest.state = "chasing"
		NestService.SetRush(false)
		NestService.SpecTakeSlot(nest, 2, thiefB)
		nest.state = "asleep"
		NestService.SpecStep(nest, os.clock() + 60)
		check(nest.pods[2] == nil and (nest.regrowAt == nil or nest.regrowAt[2] == nil),
			"outside a rush a taken slot stays empty until dawn")
		nest.state = "chasing"
		NestService.SetRush(true)
		NestService.SpecTakeSlot(nest, 3, thiefB)
		NestService.SetRush(false)
		nest.state = "asleep"
		NestService.SpecStep(nest, os.clock() + 60)
		check(nest.pods[3] == nil, "a regrowth still due when the rush ends never comes")
		NestService.SetRush(true)
		nest.state = "chasing"
		NestService.SpecTakeSlot(nest, 1, thiefB)
		Workspace:SetAttribute(phaseAttr, GameConfig.WorldCycle.PhaseNight)
		nest.state = "asleep"
		NestService.SpecStep(nest, os.clock() + 60)
		Workspace:SetAttribute(phaseAttr, phaseBefore)
		check(nest.pods[1] == nil, "nor at night")
		fakePod(2)
		nest.event = 7
		nest.state = "chasing"
		NestService.SpecTakeSlot(nest, 2, thiefB)
		check(nest.regrowAt == nil or nest.regrowAt[2] == nil, "nor on a weather event's nest: its batch is the event's")
		nest.event = nil
		check(NestService.SpecTakeSlot(nest, 2, thiefB) == false, "an empty slot is not taken twice")

		nest.state = "chasing"
		nest.target = thiefA
		nest.rage = 0
		NestService.SetRush(false)
		NestService.SpecProvoke(nest, thiefB, true)
		NestService.SpecProvoke(nest, thiefB, true)
		check(nest.rage == 2, "outside a rush every theft stacks rage", nest.rage)
		NestService.SetRush(true)
		NestService.SpecProvoke(nest, thiefB, true)
		local first = nest.rage
		NestService.SpecProvoke(nest, thiefB, true)
		NestService.SpecProvoke(nest, thiefB, false)
		check(first == 1 and nest.rage == 1, "in a rush every theft is chased at one stack: no rage builds", nest.rage)
	end)
	Workspace:SetAttribute(phaseAttr, phaseBefore)
	NestService.SetRush(false)
	NestService.SpecStealDone(nil)
	check(nests, "the nests' checks ran to the end", nestErr)

	--==========================================================================
	say("-- 5. dusk waits --")
	--==========================================================================
	local wcsScript = Server:WaitForChild("WorldCycleService")
	local function thaw(value)
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for k, v in pairs(value) do
			copy[k] = thaw(v)
		end
		return copy
	end
	local config = thaw(GameConfig)
	local standIns = {
		MapService = { SetNightBarrier = function() end, GetNightBarrier = function()
			return nil
		end },
		NestService = { ClearForNight = function()
			return 0
		end, ResetParents = function()
			return 0
		end, StockAll = function()
			return 0, 0
		end, PodCount = function()
			return 0, 0
		end, NestCount = function()
			return 0
		end },
		CarryService = { IsCarrying = function()
			return false
		end, IsLiveEventPod = function()
			return false
		end },
		BiomeGateService = { OrderAt = function()
			return 0
		end, SweepNow = function()
			return 0
		end },
	}
	local configScript = Shared:WaitForChild("GameConfig")
	local chunk = loadstring(wcsScript.Source, "=WorldCycleService")
	setfenv(chunk, setmetatable({ script = wcsScript, require = function(target)
		if target == configScript then
			return config
		end
		return assert(standIns[target.Name], "no stand-in for " .. target:GetFullName())
	end }, { __index = getfenv(1) }))
	local WCS = chunk()
	local ATTR = GameConfig.Attributes
	-- Restored by name, nil included: a table keyed by name would drop the
	-- unset ones and leave this spec's values behind in the place.
	local touched = { ATTR.WorldPhase, ATTR.WorldPhaseEndsAt, A.Until }
	local before = {}
	for i, name in ipairs(touched) do
		before[i] = Workspace:GetAttribute(name)
	end
	local dusk, duskErr = pcall(function()
		local now = Workspace:GetServerTimeNow()
		Workspace:SetAttribute(ATTR.WorldPhase, GameConfig.WorldCycle.PhaseDay)
		Workspace:SetAttribute(ATTR.WorldPhaseEndsAt, now + 60)
		Workspace:SetAttribute(A.Until, nil)
		check(WCS.HoldForRush() == false and Workspace:GetAttribute(ATTR.WorldPhaseEndsAt) == now + 60,
			"no rush: the day is left as it is")
		Workspace:SetAttribute(A.Until, now + 320)
		local held = WCS.HoldForRush()
		local endsAt = Workspace:GetAttribute(ATTR.WorldPhaseEndsAt)
		check(held and math.abs(endsAt - (now + 320 + RUSH.DuskMarginSeconds)) < 1
				and Workspace:GetAttribute(ATTR.WorldPhase) == GameConfig.WorldCycle.PhaseDay,
			"a day ending inside a rush is stretched past its end and grace", endsAt and (endsAt - now))
		check(WCS.HoldForRush() == false, "asked again, it is already long enough")
		Workspace:SetAttribute(ATTR.WorldPhaseEndsAt, now + 900)
		check(WCS.HoldForRush() == false and Workspace:GetAttribute(ATTR.WorldPhaseEndsAt) == now + 900,
			"a day that ends later anyway is left alone")
		Workspace:SetAttribute(ATTR.WorldPhase, GameConfig.WorldCycle.PhaseNight)
		Workspace:SetAttribute(ATTR.WorldPhaseEndsAt, now + 10)
		check(WCS.HoldForRush() == false and Workspace:GetAttribute(ATTR.WorldPhaseEndsAt) == now + 10,
			"a night is never touched")
	end)
	for i, name in ipairs(touched) do
		Workspace:SetAttribute(name, before[i])
	end
	local restored = true
	for i, name in ipairs(touched) do
		if Workspace:GetAttribute(name) ~= before[i] then
			restored = false
		end
	end
	check(dusk and restored, "dusk's checks ran to the end, and the Workspace is as it was", duskErr)
	local wsrc = wcsScript.Source
	local loopBody = bodyOf(wsrc, "local function runLoop()")
	check(has(loopBody, "if WorldCycleService.SecondsLeft() > 0.25\n\t\t\t\tor (WorldCycleService.IsDay() and "
			.. "WorldCycleService.HoldForRush()) then\n\t\t\t\tcontinue")
			and has(wsrc, "Workspace:GetAttributeChangedSignal(GameConfig.PodRush.Attributes.Until)"),
		"the loop sleeps on a moved deadline and asks before every dusk; a rush starting asks at once")

	--==========================================================================
	say("-- 6. the tracker and the end card on every screen --")
	--==========================================================================
	local TOPBAR = 58
	local function screen(w, h, touch, icons)
		return { safe = Vector2.new(w, h - TOPBAR), touch = touch, keyboard = not touch, icons = icons,
			viewport = Vector2.new(w, h), topbar = HudLayout.rect(0, 0, w, TOPBAR), insetTop = TOPBAR }
	end
	local SCREENS = {
		{ "desktop 1920x1080", 1920, 1080, false }, { "desktop 1366x768", 1366, 768, false },
		{ "desktop 1024x600", 1024, 600, false }, { "small window 800x600", 800, 600, false },
		{ "phone 640x480", 640, 480, true }, { "phone 772x360", 772, 360, true }, { "phone 705x338", 705, 338, true },
		{ "phone 640x360", 640, 360, true }, { "phone 801x392", 801, 392, true }, { "phone 844x390", 844, 390, true },
		{ "phone 874x402", 874, 402, true }, { "phone 896x414", 896, 414, true }, { "phone 956x440", 956, 440, true },
		{ "phone 1000x609", 1000, 609, true },
	}
	local GAP = RUSH.Tracker.Gap
	local function overlaps(a, b)
		return a.x < b.x + b.w + GAP - 1e-6 and b.x < a.x + a.w + GAP - 1e-6 and a.y < b.y + b.h + GAP - 1e-6
			and b.y < a.y + a.h + GAP - 1e-6
	end
	local bad, cards, strips = {}, {}, {}
	local guideCases = 0
	for _, s in ipairs(SCREENS) do
		for _, case in ipairs({ { false, false }, { 1, false }, { 2, false }, { 3, false }, { false, true }, { 1, true },
			{ 2, true }, { 3, true } }) do
			local icons, guide = case[1], case[2]
			local L = HudLayout.solve(screen(s[2], s[3], s[4], if icons then icons else nil))
			local phone = GameConfig.titlePhone(Vector2.new(s[2], s[3]), s[4])
			local k = if phone then RUSH.Tracker.PhoneScale else 1
			local r, layout = PodRush.trackerRect(L, TOPBAR, k, guide)
			local size = PodRush.trackerSize(k, layout)
			local why = nil
			-- The beginner's guide card (its banner and SKIP), seen in Play under the tracker: kept clear.
			if guide and r then
				guideCases += 1
				for _, g in ipairs({ L.banner, L.skip }) do
					if g and g.w > 0 and overlaps(r, g) then
						why = string.format("over the guide card (%g,%g %gx%g)", g.x, g.y, g.w, g.h)
					end
				end
			end
			if layout == "strip" or layout == "mini" then
				table.insert(strips, s[1] .. " icons " .. tostring(icons) .. (if guide then " guide" else "")
					.. (if layout == "mini" then " (mini)" else ""))
				if not phone then
					why = "a strip on a desktop"
				end
			end
			if why then
				-- already said
			elseif not r then
				why = "no spot"
			elseif r.x < GAP - 1e-6 or r.y < GAP - 1e-6 or r.x + r.w > L.safe.X - GAP + 1e-6
				or r.y + r.h > L.safe.Y - GAP + 1e-6 then
				why = "off the safe area"
			elseif math.abs(r.w - size.X) > 1e-3 or math.abs(r.h - size.Y) > 1e-3 then
				why = "wrong size"
			else
				for _, b in ipairs(PodRush.blocked(L, TOPBAR, guide)) do
					if overlaps(r, b) then
						why = string.format("meets (%g,%g %gx%g)", b.x, b.y, b.w, b.h)
						break
					end
				end
			end
			if why then
				table.insert(bad, string.format("%s icons %s: %s", s[1], tostring(icons), why))
			end
			if phone and 14 * k < 9.5 then
				table.insert(bad, s[1] .. ": the tracker's smallest words under 10 px")
			end
		end
		-- The end card over the hotbar's top, never on it (2026-10-09: TAP TO
		-- CLOSE stood over slots 3-4 on the 705 x 338 phone).
		local L0 = HudLayout.solve(screen(s[2], s[3], s[4]))
		local centre, k = PodRush.endCard(L0)
		local E = RUSH.EndCard
		local w, h = E.Width * k, E.Height * k
		local left, top = centre.X - w / 2, centre.Y - h / 2
		if left < E.Margin - 1e-6 or left + w > L0.safe.X - E.Margin + 1e-6 or top < E.Margin - 1e-6
			or top + h > L0.hotbar.y - E.Margin + 1e-6 or 12 * k < 10 then
			table.insert(cards, s[1] .. string.format(" (%.2f at %.0f,%.0f %.0fx%.0f; hotbar %.0f)", k, left, top, w, h,
				L0.hotbar.y))
		end
		-- With the guide's card up: clear of it by 8 px too, still over the hotbar.
		local gc, gk = PodRush.endCard(L0, true)
		local gr = HudLayout.rect(gc.X - E.Width * gk / 2, gc.Y - E.Height * gk / 2, E.Width * gk, E.Height * gk)
		-- (1e-3: the centre comes back as a Vector2, float32.)
		if HudLayout.gap(gr, L0.banner) < 8 - 1e-3 or HudLayout.gap(gr, L0.skip) < 8 - 1e-3
			or gr.y + gr.h > L0.hotbar.y - E.Margin + 1e-3 or gr.x < E.Margin - 1e-3
			or gr.x + gr.w > L0.safe.X - E.Margin + 1e-3 or 12 * gk < 10 then
			table.insert(cards, s[1] .. " with the guide " .. string.format("(%.3f,%.3f %.3fx%.3f) banner (%.0f,%.0f %.0fx%.0f) "
				.. "gaps %.6f %.6f", gr.x, gr.y, gr.w, gr.h, L0.banner.x, L0.banner.y, L0.banner.w, L0.banner.h,
				HudLayout.gap(gr, L0.banner), HudLayout.gap(gr, L0.skip)))
		end
	end
	check(#bad == 0 and guideCases >= 14, "the tracker finds a spot clear of the whole HUD by 8 px on 14 screens, with 0 "
		.. "to 3 boost icons, and clear of the beginner's guide card while it shows", table.concat(bad, "; "))
	say("    (the one-line strip on: " .. (if #strips > 0 then table.concat(strips, ", ") else "none") .. ")")
	local full = PodRush.trackerRect(HudLayout.solve(screen(1366, 768, false, 3)), TOPBAR, 1)
	local _, fullLayout = PodRush.trackerRect(HudLayout.solve(screen(1366, 768, false, 3)), TOPBAR, 1)
	check(full ~= nil and fullLayout == "full" and #strips < 14 * 8,
		"a desktop always has the whole tracker; a strip only where a phone has no room for it")
	local line = PodRush.stripLine(5, 192, false)
	local bankLine = PodRush.stripLine(5, 14, true)
	local mini = PodRush.stripLine(5, 192, false, true)
	check(has(line, "3:12</font>  5 banked \u{00B7} 2 more for SILVER") and has(line, RUSH.Ring.Colour:ToHex())
			and has(bankLine, "BANK IT! 0:14</font>") and has(bankLine, RUSH.Tracker.BankItColour:ToHex())
			and has(mini, "3:12</font>  5 banked") and not has(mini, "more for"),
		"the strip says the time (BANK IT! after the end), the pods banked and the next goal; the mini the first two")
	check(#cards == 0, "the end card stands over the hotbar on all 14 screens, TAP TO CLOSE clear of it by 16 px, its "
		.. "smallest words 10 px or more -- and 8 px clear of the guide's card while that shows",
		table.concat(cards, "; "))

	--==========================================================================
	say("-- 7. the wiring --")
	--==========================================================================
	local adminSrc = sourceOf(Server, "AdminService")
	local consoleSrc = sourceOf(Server, "AdminConsoleUI")
	check(has(adminSrc, "\tpodrush = true,\n") and has(consoleSrc, "{ \"PodRush\", \"POD RUSH\" },")
			and has(consoleSrc, "{ verb = \"podrush\", button = modes[5] },")
			and has(consoleSrc, "local own = tonumber(((MINI.Modes :: any)[choice.verb] or {}).Seconds)")
			and has(consoleSrc, "podrush = string.format(\"POD RUSH:"),
		"the console starts it like the other four: its chip, its words, its five minutes in the box")
	local okMes, MES = pcall(require, Server:WaitForChild("MiniEventService"))
	check(okMes and MES.ValidRecord({ v = 1, ns = "spec", id = "abcdef1234567890", rev = 1, mode = "podrush",
		startedAt = 1000, endsAt = 1300, state = "running", by = 90000000001, byName = "Spec", endedIds = {} }) == true,
		"the shared record carries it to every server", if okMes then nil else MES)

	local BoostIcons = require(Shared:WaitForChild("BoostIcons"))
	local function snap(rushId, count, state)
		return { now = 1000, miniState = state or "running", miniMode = "podrush", miniStartedAt = 990, miniEndsAt = 1290,
			miniId = "rushAAAA11112222", podRushId = rushId, podRushCount = count }
	end
	local e1 = BoostIcons.entries(snap("rushAAAA11112222", 5))[1]
	local e2 = BoostIcons.entries(snap("oldrush", 9))[1]
	check(#BoostIcons.entries(snap("rushAAAA11112222", 5)) == 1 and e1.id == "podrush" and e1.source == "podrush"
			and e1.badge == "5" and e1.hint == "5 banked this rush." and e1.total == 300 and e1.endsAt == 1290
			and e1.effect == "Bank pods taken from nests: 3 bronze, 7 silver, 12 gold." and e2.badge == "0"
			and #BoostIcons.entries(snap("rushAAAA11112222", 5, "ending")) == 0,
		"the boost row: the rush's own icon with this player's count, never another rush's; none once it ends")
	local order = table.concat(GameConfig.BoostIcons.Order, ",")
	check(has(order, "tickets,podrush,income") and GameConfig.BoostIcons.Tints.podrush ~= nil,
		"its place in the row, after the tickets")
	local watched = false
	for _, w in ipairs(BoostIcons.watched()) do
		if w.on == "player" and w.name == A.Count then
			watched = true
		end
	end
	check(watched, "the row redraws when the count changes")

	local StatusText = require(Shared:WaitForChild("StatusText"))
	local holder = Instance.new("Frame")
	holder.Parent = fixture
	local rushIcon = StatusText.icon(holder, "boost", Color3.new(1, 1, 1), 30, "podrush")
	local ticketIcon = StatusText.icon(holder, "boost", Color3.new(1, 1, 1), 30, "tickets")
	local p1, p2 = rushIcon:FindFirstChild("Picture"), ticketIcon:FindFirstChild("Picture")
	check(p1 and p1.Image == ART.Icon and p1.ImageRectOffset == ART.CropOffset and p1.ImageRectSize == ART.CropSize
			and p2 and p2.ImageRectSize == Vector2.zero,
		"a notice or boost icon draws the rush icon by its crop, and the others as before")

	local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))
	local d = ProfileSchema.Default().PodRush
	local s = ProfileSchema.Sanitise({ PodRush = { Id = "bad id!", Count = -4, Paid = 9, Top = 99, PodOwed = "moon" } }).PodRush
	local g = ProfileSchema.Sanitise({ PodRush = { Id = "rushAAAA11112222", Count = 13.7, Paid = 3, Top = 5,
		PodOwed = "dustbowl,moon,starbloom" } }).PodRush
	check(d and d.Id == "" and d.Count == 0 and d.Paid == 0 and d.Top == 0 and d.PodOwed == ""
			and s.Id == "" and s.Count == 0 and s.Paid == #RUSH.Levels and s.Top == #BiomeData.Biomes and s.PodOwed == ""
			and g.Id == "rushAAAA11112222" and g.Count == 13 and g.Paid == 3 and g.Top == 5
			and g.PodOwed == "dustbowl,starbloom" and ProfileSchema.Sanitise({}).PodRush.Id == "",
		"the saved row: an empty one for old saves, junk cleaned, a good one kept")
	local pdsSrc = sourceOf(Server, "PlayerDataService")
	check(has(pdsSrc, "function PlayerDataService.UpdatePodRush(player: Player, change: (Profile) -> boolean): boolean")
			and has(pdsSrc, "PodRush = table.clone(profile.PodRush"),
		"saved through PlayerDataService, and kept by a progress reset so no level pays twice")

	local Metrics = require(Server:WaitForChild("Metrics"))
	local metricsSrc = sourceOf(Server, "Metrics")
	check(Metrics.Events.PodRushEnded == "PodRushEnded" and type(Metrics.podRushEnded) == "function"
			and has(bodyOf(metricsSrc, "function Metrics.podRushEnded"), "{ [F1] = level }"),
		"PodRushEnded: the count and the level's word, no names or ids")

	local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	local musicSrc = sourceOf(scripts, "Music")
	local discoAt = musicSrc:find("if #discoTracks > 0 and discoOk ~= false and discoPlaying() then", 1, true)
	local rushAt = musicSrc:find("if #rushTracks > 0 and rushOk ~= false and rushPlaying() then", 1, true)
	local rainAt = musicSrc:find("if #rainTracks > 0 and rainOk ~= false and rainFalling() then", 1, true)
	local _, sounds = musicSrc:gsub("Instance%.new%(\"Sound\"%)", "")
	check(GameConfig.Music.PodRushTrack == "" and discoAt and rushAt and rainAt and discoAt < rushAt and rushAt < rainAt
			and has(musicSrc, "local rushTracks: { string } = usable({ (MUSIC :: any).PodRushTrack })")
			and has(musicSrc, "return mode ~= nil and mode.PodRush == true") and sounds == 2,
		"the music: the rush's own bed in the disco's place, \"\" until the owner's track comes; one probe for every bed")
	local cues = GameConfig.Sfx.Cues
	check(cues.PodRushStart and cues.PodRushStart.id == "" and cues.PodRushFinish and cues.PodRushFinish.id == "",
		"the start and finish stings are silent slots for now")

	local carrySrc = sourceOf(Server, "CarryService")
	local bankBody = bodyOf(carrySrc, "local function bank(player: Player): boolean")
	local raidAt = bankBody:find("Metrics.raidEnded(player, \"banked\")", 1, true)
	local tellAt = bankBody:find("for _, listener in ipairs(table.clone(onBanked)) do", 1, true)
	check(has(carrySrc, "stolenAt = nestTheft and workspace:GetServerTimeNow() or nil,")
			and has(carrySrc, "function CarryService.OnBanked(") and has(carrySrc, "function CarryService.CarriedTheft(")
			and raidAt and tellAt and raidAt < tellAt and has(bankBody, "local ok, err = pcall(listener, player, info)"),
		"a nest theft is stamped with its time and only a nest theft; the bank tells its listeners after it is done")
	local nestSrc = sourceOf(Server, "NestService")
	check(has(bodyOf(nestSrc, "function NestService.TakePod"), "takeSlot(nest, slot, pod, thief)")
			and has(nestSrc, "if rushOn then\n\t\tnest.rage = 1\n\telse\n\t\tnest.rage += 1"),
		"the nests: TakePod takes through takeSlot; a rush pins the rage")

	local serviceSrc = sourceOf(Server, "PodRushService")
	local PRS = require(Server:WaitForChild("PodRushService"))
	check(PRS.Priority > 70 and not has(serviceSrc, "OnServerEvent") and has(serviceSrc, "CarryService.OnBanked("),
		"the service: after the world cycle, takes nothing from a client, hears every bank")
	local uiSrc = sourceOf(scripts, "PodRushUI")
	check(has(uiSrc, "PodRush.trackerRect(L, input.insetTop or 0, k, guideShowing())")
			and has(uiSrc, "return UIKit.guideShowing(playerGui)")
			and has(uiSrc, "StatusText.reducedMotion()")
			and has(uiSrc, "SoundKit.play(\"PodRushStart\")") and has(uiSrc, "SoundKit.play(\"PodRushFinish\")")
			and has(uiSrc, "GameConfig.Tags.NestSite") and not has(uiSrc, "FireServer")
			and has(uiSrc, "part.CanCollide = false") and has(uiSrc, "part.CanQuery = false"),
		"the client: placed by the shared rule, no pops with REDUCED FX, the stings, the rings, and it sends nothing")
	-- The owner (2026-10-09): "pod rush gui must be transparent, everything must be transparent, applies to buffs,
	-- and effects".
	check(has(uiSrc, "tracker.BackgroundTransparency = 1") and has(uiSrc, "strip.BackgroundTransparency = 1")
			and has(uiSrc, "card.BackgroundTransparency = 1") and has(uiSrc, "bar.BackgroundTransparency = 1")
			and not has(uiSrc, "UIKit.stroke(tracker,") and not has(uiSrc, "UIKit.stroke(strip,")
			and not has(uiSrc, "UIKit.stroke(card,") and has(uiSrc, "UIKit.stroke(fill, Color3.new(0, 0, 0), 1.5)"),
		"transparent, as the owner asked: no plate or edge behind the tracker, the strip or the end card; the bar's fill "
			.. "alone, outlined")
	local iconsUi = sourceOf(scripts, "BoostIconsUI")
	check(iconsUi ~= "" and not has(iconsUi, "\"Plate\"") and has(iconsUi, "badge.BackgroundTransparency = 1")
			and has(iconsUi, "popover.BackgroundTransparency = 1") and has(iconsUi, "caret.BackgroundTransparency = 1")
			and not has(iconsUi, "MenuKit.keyline(popover") and has(iconsUi, "UIKit.stroke(badge, Color3.new(0, 0, 0), 1.5)"),
		"and the buff row: no plate behind an icon, its count or its popover; every word outlined")
end)

fixture:Destroy()
if not ok then
	fail += 1
	say("  FAIL  THREW: " .. tostring(err))
end
say(string.format("PodRushSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
