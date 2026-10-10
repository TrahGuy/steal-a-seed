--!nocheck
--==============================================================================
-- Steal a Seed :: RebirthSpec (2026-10-08)
--
-- REBIRTH: the owner's "rebirth first, cash and mill tier reset, plan it" /
-- "we should also do a fence upgrade every rebirth and a title above the name"
-- / "use your defaults". The pure rulebook (Shared/Rebirth): the price ladder
-- under the save's cash cap, the mill requirement, the bonuses, the titles,
-- the fence tiers, what blocks one. The save's two new fields. The REAL
-- RebirthService, its siblings stood in: a rebirth spends exactly the cash and
-- puts back exactly the mill and keeps everything else, refuses what it must,
-- happens once per token and saves at once; the fence keeps every board's
-- size, place and collision; the title over the name, ADMIN on top. And the
-- wiring: the income bonus where the pass is, the offline card, the shrine's
-- ground. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("RebirthSpec"))
--
-- Not here, seen in Play instead: the shrine, the panel and a real rebirth.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = game:GetService("ServerScriptService").SeedGameServer
local Scripts = game:GetService("StarterPlayer").StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local Rebirth = require(Shared.Rebirth)
local WheelData = require(Shared.WheelData)
local ProfileSchema = require(Server.ProfileSchema)

local CFG = GameConfig.Rebirth
local TITLE = CFG.Title

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
		say("  FAIL  " .. label .. (if detail ~= nil and detail ~= "" then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local s = parent:FindFirstChild(name, true)
	return if s then s.Source else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
-- Instance properties hold float32: compare what was set with a tolerance.
local function near(a, b)
	return math.abs(a - b) <= 1e-4
end
local function hex(c)
	return c:ToHex()
end

local scratch = Instance.new("Folder")
scratch.Name = "ZZRebirthSpec"
scratch.Archivable = false
scratch.Parent = Workspace

local ok, err = pcall(function()
	--==========================================================================
	say("1. The price ladder, the requirement, the bonuses")
	--==========================================================================
	check(Rebirth.priceFor(1) == 1e9 and Rebirth.priceFor(2) == 4e9 and Rebirth.priceFor(3) == 1.6e10
		and Rebirth.priceFor(4) == 6.4e10 and Rebirth.nextPrice(0) == 1e9 and Rebirth.nextPrice(3) == 6.4e10,
		"rebirth 1 needs $1B, then x4 each time: $4B, $16B, $64B")
	local within = true
	for k = 1, 60 do
		if Rebirth.priceFor(k) > GameConfig.Save.MaxCash or Rebirth.priceFor(k) > CFG.PriceCap then
			within = false
		end
	end
	check(Rebirth.priceFor(10) == 1e9 * 4 ^ 9 and Rebirth.priceFor(11) == CFG.PriceCap and Rebirth.priceFor(50) == CFG.PriceCap
		and CFG.PriceCap <= GameConfig.Save.MaxCash and within,
		"x4 stops at the cap from rebirth 11 on: no price ever past the save's $1Qa, so every title can be reached",
		string.format("10th %s, 11th %s", GameConfig.compact(Rebirth.priceFor(10)), GameConfig.compact(Rebirth.priceFor(11))))
	local tier, name = Rebirth.millNeeded()
	check(tier == 8 and name == "Inferno Forge" and GameConfig.Mill.Tiers[8].cost == 1e9,
		"and the mill at Inferno Forge (tier 8, itself $1B) first", name)
	check(Rebirth.training(0) == 1 and Rebirth.training(1) == 1.5 and Rebirth.training(2) == 2 and Rebirth.training(4) == 3
		and Rebirth.income(0) == 1 and Rebirth.income(1) == 1.25 and Rebirth.income(4) == 2,
		"+50% training and +25% income per rebirth, added up")
	check(GameConfig.rebirthMultiplierFor(nil) == 1 and GameConfig.rebirthMultiplierFor({}) == 1
		and GameConfig.trainingRateFor(1, { Rebirths = 1 }) == GameConfig.Mill.Tiers[1].speed * 1.5
		and GameConfig.trainingRateFor(8, { Rebirths = 2 }) == GameConfig.Mill.Tiers[8].speed * 2,
		"the training seam carries it into every training rate (the payout, the sign, the shop, SpeedFX)")
	check(Rebirth.times(1.5) == "1.5" and Rebirth.times(2) == "2" and Rebirth.times(2.25) == "2.25"
		and Rebirth.times(1.25) == "1.25" and Rebirth.times(3.5) == "3.5",
		"multipliers print as 1.5, 2, 2.25")
	local fakeShown = { GetAttribute = function(_, attr)
		return if attr == CFG.Attributes.Rebirths then 2 else nil
	end }
	check(GameConfig.rebirthIncomeOf(nil) == 1 and GameConfig.rebirthIncomeOf(fakeShown) == 1.5,
		"the displays read the published count: x1.5 income at two")

	--==========================================================================
	say("2. Titles and fences")
	--==========================================================================
	local function titleText(n)
		local s = Rebirth.title(n)
		return s and s.Text or "-"
	end
	check(titleText(0) == "-" and titleText(1) == "SPROUT" and titleText(2) == "SEEDLING" and titleText(3) == "GARDENER"
		and titleText(4) == "GREEN THUMB" and titleText(6) == "BOTANIST" and titleText(7) == "HERBALIST"
		and titleText(14) == "GROVE KEEPER" and titleText(15) == "BLOOM WARDEN" and titleText(20) == "THORN KNIGHT"
		and titleText(29) == "ELDER ROOT" and titleText(30) == "CANOPY LORD" and titleText(40) == "ANCIENT OAK"
		and titleText(50) == "WORLD TREE" and titleText(75) == "EVERBLOOM" and titleText(100) == "GAIA"
		and titleText(400) == "GAIA",
		"fifteen steps (the owner: \"yes add more titles\"): SPROUT at 1 ... WORLD TREE at 50, EVERBLOOM at 75, GAIA at 100")
	local rising, previous = #TITLE.Ladder == 15, 0
	for _, step in ipairs(TITLE.Ladder) do
		if step.At <= previous then
			rising = false
		end
		previous = step.At
	end
	check(rising and TITLE.Ladder[13].Rainbow == nil and TITLE.Ladder[15].Rainbow == true
		and Rebirth.priceFor(100) <= GameConfig.Save.MaxCash,
		"thresholds strictly rising; WORLD TREE gold and still, the rainbow GAIA's alone; 100 rebirths payable")
	local function lum(c)
		local function lin(v)
			return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
		end
		return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
	end
	local ink = lum(require(Shared.FloatingSign).Outline)
	local worstContrast, worstWord = math.huge, ""
	for _, step in ipairs(TITLE.Ladder) do
		local ratio = (lum(step.Colour) + 0.05) / (ink + 0.05)
		if ratio < worstContrast then
			worstContrast, worstWord = ratio, step.Text
		end
	end
	check(worstContrast >= 3, "every title colour stands off its dark outline (over sky, grass and night alike)",
		string.format("lowest: %s at %.1f:1", worstWord, worstContrast))
	local rows0, high0, next0 = Rebirth.ladder(0)
	local _, high6, next6 = Rebirth.ladder(6)
	local rows100, high100, next100 = Rebirth.ladder(100)
	check(#rows0 == 15 and high0 == 0 and next0 == 1 and rows0[1].state == "next" and rows0[2].state == "locked"
		and high6 == 5 and next6 == 6 and high100 == 15 and next100 == 0 and rows100[15].state == "reached",
		"the ladder's states: the highest reached (BOTANIST at six), the next (HERBALIST), the rest locked")
	local colours, rainbowOnlyTop = {}, true
	for i, step in ipairs(TITLE.Ladder) do
		colours[hex(step.Colour)] = true
		if (step.Rainbow == true) ~= (i == #TITLE.Ladder) then
			rainbowOnlyTop = false
		end
	end
	local distinct = 0
	for _ in pairs(colours) do
		distinct += 1
	end
	check(distinct == #TITLE.Ladder and rainbowOnlyTop, "each in its own colour; only the top one a rainbow")
	local F = CFG.Fence
	local fences = {}
	for n = 0, 7 do
		fences[n] = Rebirth.fence(n)
	end
	local capsOk = fences[0].style.Cap == nil
	for t = 1, #F.Tiers do
		capsOk = capsOk and F.Tiers[t].Cap ~= nil and fences[t].tier == t
	end
	check(fences[0].tier == 0 and fences[0].style.Name == "Wood" and fences[1].style.Name == "White picket"
		and fences[2].style.Name == "Stone" and fences[3].style.Name == "Iron" and fences[4].style.Name == "Marble"
		and fences[5].style.Name == "Crystal" and fences[6].style.Name == "Gold" and fences[7].tier == 6 and capsOk,
		"the fence ladder: wood, white picket, stone, iron, marble, crystal, then gold for good")
	check(Rebirth.fence(6).trim == F.Trims[1] and Rebirth.fence(9).trim == F.Trims[1] and Rebirth.fence(10).trim == F.Trims[2]
		and Rebirth.fence(6 + F.TrimEvery * #F.Trims).trim == F.Trims[1] and Rebirth.fence(5).trim == nil,
		"the gold fence's gems step colour every few rebirths, round again after the last")

	--==========================================================================
	say("3. What stops a rebirth")
	--==========================================================================
	local base = { ready = true, now = 1000, lastAt = 0, rebirths = 0, cash = 2e9, millTier = 8 }
	local function with(changes)
		local s = table.clone(base)
		for k, v in pairs(changes) do
			s[k] = v
		end
		return Rebirth.check(s)
	end
	check(with({}) == nil, "rich enough, Inferno Forge, free: it may go ahead")
	check(with({ ready = false }) == "NOT_READY" and with({ enabled = false }) == "DISABLED"
		and with({ lastAt = 995 }) == "COOLDOWN" and with({ lastAt = 1000 - CFG.CooldownSeconds }) == nil
		and with({ busy = true }) == "BUSY" and with({ dead = true }) == "DEAD"
		and with({ carrying = true }) == "CARRYING" and with({ chased = true }) == "CHASED"
		and with({ offline = true }) == "OFFLINE" and with({ millTier = 7 }) == "MILL" and with({ cash = 9.99e8 }) == "CASH"
		and with({ rebirths = 1 }) == "CASH",
		"not loaded, closed, cooling down, a purchase in flight, dead, carrying a pod, chased, an offline claim "
			.. "waiting, the mill short, the cash short")
	check(with({ carrying = true, millTier = 1, cash = 0 }) == "CARRYING",
		"the first thing a player can do something about comes first")
	check(has(Rebirth.refusal("MILL", 0), "Inferno Forge") and has(Rebirth.refusal("CASH", 1), GameConfig.money(4e9))
		and Rebirth.refusal("OFFLINE", 0) == CFG.Words.Refused.OFFLINE,
		"each refusal in plain words, with its number")

	--==========================================================================
	say("4. The save")
	--==========================================================================
	local fresh = ProfileSchema.Default()
	check(fresh.Rebirths == 0 and fresh.RebirthAt == 0, "a new save: 0 rebirths, never reborn")
	local old = ProfileSchema.Sanitise({})
	local odd = ProfileSchema.Sanitise({ Rebirths = 3.7, RebirthAt = -5 })
	local nan = ProfileSchema.Sanitise({ Rebirths = 0 / 0, RebirthAt = "x" })
	local kept = ProfileSchema.Sanitise({ Rebirths = 12, RebirthAt = 1791460000 })
	check(old.Rebirths == 0 and old.RebirthAt == 0 and odd.Rebirths == 3 and odd.RebirthAt == 0
		and nan.Rebirths == 0 and nan.RebirthAt == 0 and kept.Rebirths == 12 and kept.RebirthAt == 1791460000,
		"an old save reads 0 and 0; a broken value whole and never below 0; a good one exactly as saved")
	local pds = sourceOf(Server, "PlayerDataService")
	check(has(pds, "Rebirths = GameConfig.rebirthCount(profile.Rebirths),")
			and has(pds, "RebirthAt = GameConfig.rebirthCount(profile.RebirthAt),")
			and select(2, string.gsub(pds, "PlayerDataService.PublishRebirth%(player%)", "")) >= 3
			and has(pds, 'rebirths.Name = "Rebirths"'),
		"the admin progress reset keeps them, the count is published on load and reset, and a Rebirths column joins "
			.. "the player list")

	--==========================================================================
	say("5. The real RebirthService, its siblings stood in")
	--==========================================================================
	local profiles, carrying, deciding, plots, owners = {}, {}, {}, {}, {}
	local calls = { unmount = 0, rebuild = {}, save = 0 }
	local fakePDS = {
		Get = function(p)
			return profiles[p]
		end,
		IsReady = function(p)
			return profiles[p] ~= nil
		end,
		AddCash = function(p, amount)
			local pr = profiles[p]
			pr.Cash = math.max(0, pr.Cash + amount)
			return pr.Cash
		end,
		SetMillTier = function(p, t)
			profiles[p].MillTier = t
			return true
		end,
		UpdateRebirth = function(p, change)
			if change(profiles[p]) then
				p:SetAttribute(CFG.Attributes.Rebirths, profiles[p].Rebirths)
				return true
			end
			return false
		end,
		Save = function()
			calls.save += 1
			return true
		end,
	}
	local fakePlots = {
		PlotOf = function(p)
			return plots[p]
		end,
		OwnerOf = function(plot)
			return owners[plot]
		end,
		OnAssigned = function()
			return function() end
		end,
		OnReleased = function()
			return function() end
		end,
		OnResized = function()
			return function() end
		end,
	}
	local fakeTread = {
		Unmount = function()
			calls.unmount += 1
		end,
		Rebuild = function(plot, t)
			table.insert(calls.rebuild, { plot, t })
		end,
	}
	local siblings = {
		PlayerDataService = fakePDS,
		PlotService = fakePlots,
		TreadmillService = fakeTread,
		CarryService = { IsCarrying = function(p)
			return carrying[p] == true
		end },
		StoreService = { Deciding = function(p)
			return deciding[p] == true
		end },
	}
	local parent = {}
	function parent:WaitForChild(childName)
		assert(siblings[childName] ~= nil, "unexpected sibling " .. childName)
		return { __standIn = siblings[childName] }
	end
	local outerRequire = require
	local chunk = assert(loadstring(sourceOf(Server, "RebirthService"), "=RebirthService"))
	setfenv(chunk, setmetatable({
		script = { Name = "RebirthService", Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) }))
	local Service = chunk()
	local now, clock = 1791460000, 100
	local replies = {}
	local distance = 5
	Service.Hooks.now = function()
		return now
	end
	Service.Hooks.clock = function()
		return clock
	end
	Service.Hooks.reply = function(p, payload)
		table.insert(replies, { player = p, payload = payload })
	end
	Service.Hooks.distance = function()
		return distance
	end

	local made = 0
	local function fakePlayer(label, profile)
		made += 1
		local attrs = {}
		-- Simulated ids only (from 90,000,000,000).
		local p = { Name = label, UserId = 90000000000 + made }
		function p:GetAttribute(k)
			return attrs[k]
		end
		function p:SetAttribute(k, v)
			attrs[k] = v
		end
		local model = Instance.new("Model")
		model.Name = "ZZReborn_" .. label
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Anchored = true
		head.Parent = model
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = model
		model.Parent = scratch
		p.Character = model
		profiles[p] = profile
		return p, humanoid, head
	end
	local function richProfile()
		return {
			Cash = 3.5e9, MillTier = 9, Rebirths = 0, RebirthAt = 0, Speed = 123456789, PlotTier = 6,
			Plants = { { SpeciesId = "petalpip", Slot = 1 } }, Held = { { Id = "i1" } }, Weapons = { "bat" },
			WheelBought = 7, SpeedMilestone = 4, Seen = { petalpip = true }, InviteOwned = { "dustthorn" },
			ChestBoostEndsAt = 1791460500, SproutBoostEndsAt = 1791460400,
		}
	end
	local function last()
		return replies[#replies] and replies[#replies].payload
	end

	-- Quotes for somebody not there yet.
	local poor = fakePlayer("Poor", { Cash = 5e8, MillTier = 3, Rebirths = 0, RebirthAt = 0 })
	local q0 = Service.Quote(poor)
	local mid = fakePlayer("Mid", { Cash = 5e8, MillTier = 8, Rebirths = 0, RebirthAt = 0 })
	local q1 = Service.Quote(mid)
	check(q0.ok == false and q0.why == "MILL" and q1.ok == false and q1.why == "CASH" and q1.price == 1e9
		and has(q1.words, GameConfig.money(1e9)),
		"the shrine's quote says what is missing: the mill first, then the cash")

	local hero, _, heroHead = fakePlayer("Hero", richProfile())
	local plot = Instance.new("Model")
	plot.Name = "ZZRebirthPlot"
	plot.Parent = scratch
	plots[hero] = plot
	owners[plot] = hero
	local before = table.clone(profiles[hero])
	local q = Service.Quote(hero)
	check(q.ok == true and q.price == 1e9 and q.rebirths == 0 and q.nextTraining == 1.5 and q.nextIncome == 1.25
		and type(q.token) == "number",
		"rich and on Inferno Forge or better: the quote is a yes, with a token")
	check(Service.Confirm(hero, { token = q.token + 999 }) == false and last().verb == "refused" and last().why == "QUOTE",
		"a token the shrine never gave is refused")
	distance = 40
	check(Service.Confirm(hero, { token = q.token }) == false and last().why == "FAR", "and from across the square")
	distance = 5
	local done = Service.Confirm(hero, { token = q.token })
	local p = profiles[hero]
	check(done == true and last().verb == "done" and last().rebirths == 1 and last().training == 1.5
		and last().income == 1.25 and last().saved == true,
		"the second press, the right token, at the shrine: reborn, and told so")
	check(p.Cash == 0 and p.MillTier == 1 and p.Rebirths == 1 and p.RebirthAt == now
		and calls.unmount == 1 and #calls.rebuild == 1 and calls.rebuild[1][1] == plot and calls.rebuild[1][2] == 1
		and calls.save == 1,
		"all the cash spent, the mill back to tier 1 and rebuilt (its rider off first), counted, saved at once")
	local changed = {}
	for k, v in pairs(before) do
		if k ~= "Cash" and k ~= "MillTier" and k ~= "Rebirths" and k ~= "RebirthAt" and p[k] ~= v then
			table.insert(changed, k)
		end
	end
	check(#changed == 0 and p.Speed == before.Speed and p.PlotTier == 6 and p.Plants == before.Plants
		and p.Weapons == before.Weapons and p.WheelBought == 7 and p.SpeedMilestone == 4 and p.Seen == before.Seen,
		"and NOTHING else: Speed, the plot's level, plants, the Bag, weapons, spin tickets, milestones, the Index, "
			.. "invite plants, running boosts", table.concat(changed, ", "))
	check(hero:GetAttribute(CFG.Attributes.Rebirths) == 1, "the count is published")
	check(Service.Confirm(hero, { token = q.token }) == false and last().why == "QUOTE" and profiles[hero].Rebirths == 1,
		"the same token again (a double press, a replayed packet): refused, still one rebirth")
	local again = Service.Quote(hero)
	check(again.why == "COOLDOWN" and Service.Confirm(hero, { token = again.token }) == false
		and last().why == "COOLDOWN",
		"and a new quote at once is cooling down")

	-- The blocks, on a fresh rich player each.
	local function blockedBy(setup)
		local who, humanoid = fakePlayer("Blocked" .. made, richProfile())
		setup(who, humanoid)
		return Service.Quote(who).why
	end
	local reasons = {
		blockedBy(function(who)
			carrying[who] = true
		end),
		blockedBy(function(who)
			who:SetAttribute(GameConfig.Attributes.PursuedBy, 1)
		end),
		blockedBy(function(who)
			who:SetAttribute(GameConfig.OfflineEarnings.Attributes.Cash, 500)
		end),
		blockedBy(function(who)
			deciding[who] = true
		end),
		blockedBy(function(_, humanoid)
			humanoid.Health = 0
		end),
	}
	check(table.concat(reasons, ",") == "CARRYING,CHASED,OFFLINE,BUSY,DEAD",
		"carrying a pod, chased, an offline claim waiting, a purchase in flight, dead: each refused by name",
		table.concat(reasons, ","))

	--==========================================================================
	say("6. The title over the name, ADMIN on top")
	--==========================================================================
	local gui = heroHead:FindFirstChild(TITLE.Name)
	check(gui ~= nil and gui.Words.Text == "SPROUT" and gui.Sub.Text == "REBIRTH 1"
		and hex(gui.Words.TextColor3) == hex(TITLE.Ladder[1].Colour) and CollectionService:HasTag(gui, TITLE.Tag)
		and gui.Adornee == heroHead and gui.MaxDistance == TITLE.MaxDistance and gui.AlwaysOnTop == false,
		"reborn once: SPROUT over the name, REBIRTH 1 under it, on the Head")
	check(gui ~= nil and gui.Size == UDim2.fromOffset(TITLE.Size.X, TITLE.Size.Y) and gui.Words.TextSize == TITLE.TextSize
			and gui.Sub.TextSize == TITLE.SubTextSize and gui.Words.Size == UDim2.fromScale(1, 0.6)
			and gui.Sub.Position == UDim2.fromScale(0, 0.6) and gui.Sub.Size == UDim2.fromScale(1, 0.4),
		"built at the smaller desktop size: six tenths of it for the words, four for REBIRTH N")
	local admin = Instance.new("BillboardGui")
	admin.Name = GameConfig.OwnerTitle.Name
	admin.Parent = heroHead
	profiles[hero].Rebirths = 50
	Service.ApplyTitle(hero, hero.Character)
	local gold = heroHead:FindFirstChild(TITLE.Name)
	local goldStill = gold ~= nil and gold.Words.Text == "WORLD TREE I" and gold.Words:FindFirstChild("Rainbow") == nil
	profiles[hero].Rebirths = 100
	Service.ApplyTitle(hero, hero.Character)
	local top = heroHead:FindFirstChild(TITLE.Name)
	local adminBottom = (GameConfig.ownerTitleLift(true) - 0.5) * GameConfig.OwnerTitle.Size.Y
	local rebirthTop = (TITLE.Lift + 0.5) * TITLE.Size.Y
	check(goldStill and top ~= nil and top.Words.Text == "GAIA I" and top.Words:FindFirstChild("Rainbow") ~= nil
		and #heroHead:GetChildren() == 2 and near(admin.SizeOffset.Y, GameConfig.ownerTitleLift(true))
		and adminBottom >= rebirthTop + 1 and GameConfig.ownerTitleLift(false) == GameConfig.OwnerTitle.Lift,
		"WORLD TREE I at fifty in plain gold, GAIA I at a hundred in the rainbow; one title per head; with ADMIN "
			.. "both show, ADMIN on top", string.format("ADMIN's foot %.1f px, the title's top %.1f px", adminBottom, rebirthTop))
	-- A phone draws the title at PhoneScale (OwnerTitleUI); ADMIN comes down with it.
	local phoneTitle = GameConfig.rebirthTitleLook(TITLE.PhoneScale)
	local phoneAdminBottom = (GameConfig.ownerTitleLift(true, TITLE.PhoneScale) - 0.5) * GameConfig.OwnerTitle.Size.Y
	local phoneTop = (TITLE.Lift + 0.5) * phoneTitle.Y
	check(phoneAdminBottom >= phoneTop + 1 and phoneAdminBottom <= phoneTop + 3 and adminBottom <= rebirthTop + 3
			and GameConfig.ownerTitleLift(true, 1) == GameConfig.ownerTitleLift(true),
		"on a phone ADMIN comes down with the smaller title and stays two pixels clear of it, as on a desktop",
		string.format("phone: ADMIN's foot %.1f px, the title's top %.1f px", phoneAdminBottom, phoneTop))
	-- ADMIN on a phone too (2026-10-09, the owner: "shrink admin on phones too"): its letters at PhoneTextSize, its
	-- box and outlines with them, still two pixels over a phone's title; a desktop's ADMIN exactly as built. 15 matches
	-- a player's name: on the owner's phone screenshot the engine's name tag's capitals are 11.4 points tall (28 px
	-- where the top bar's 44-point button is 108 px); ADMIN at 15 draws 12 points with its outline.
	local T = GameConfig.OwnerTitle
	local adminPhone = GameConfig.ownerTitleScale(Vector2.new(705, 338), true)
	local adminLook = GameConfig.ownerTitleLook(adminPhone)
	local deskAdmin = GameConfig.ownerTitleLook(1)
	local adminFoot = (GameConfig.ownerTitleLift(true, TITLE.PhoneScale, adminPhone) - 0.5) * adminLook.box.Y
	local adminWide = game:GetService("TextService"):GetTextSize(T.Text, adminLook.text, Enum.Font.FredokaOne,
		Vector2.new(1000, 1000))
	check(adminLook.text == T.PhoneTextSize and adminLook.text < T.TextSize
			and GameConfig.ownerTitleScale(Vector2.new(1024, 768), true) == 1
			and GameConfig.ownerTitleScale(Vector2.new(705, 338), false) == 1
			and deskAdmin.box == T.Size and deskAdmin.text == T.TextSize and deskAdmin.glow == T.GlowThickness
			and deskAdmin.edge == T.EdgeThickness and adminLook.edge >= 1 and adminLook.glow >= 1
			and adminWide.X + 2 * adminLook.edge <= adminLook.box.X and adminWide.Y <= adminLook.box.Y
			and adminFoot >= phoneTop + 1 and adminFoot <= phoneTop + 3,
		"on a phone ADMIN's letters are " .. T.PhoneTextSize .. " px, the word fits its smaller box, two pixels over the "
			.. "phone's title; on a desktop ADMIN is exactly as built",
		string.format("phone ADMIN %dx%d at %.1f, its foot %.1f, the title's top %.1f", adminLook.box.X, adminLook.box.Y,
			adminLook.text, adminFoot, phoneTop))
	profiles[hero].Rebirths = 0
	Service.ApplyTitle(hero, hero.Character)
	check(heroHead:FindFirstChild(TITLE.Name) == nil and near(admin.SizeOffset.Y, GameConfig.OwnerTitle.Lift),
		"none before the first rebirth, and ADMIN back down to its own place")

	--==========================================================================
	say("7. The fence: colours, materials and untouchable caps ONLY")
	--==========================================================================
	local fencePlot = Instance.new("Model")
	fencePlot.Name = "ZZFencePlot"
	fencePlot.Parent = scratch
	local wood = Color3.fromRGB(96, 66, 44)
	local function piece(pieceName, size, at, transparency)
		local part = Instance.new("Part")
		part.Name = pieceName
		part.Size = size
		part.CFrame = CFrame.new(at)
		part.Anchored = true
		part.Transparency = transparency or 0
		part.Color = wood
		part.Material = Enum.Material.Wood
		part.Parent = fencePlot
		return part
	end
	local pieces = {
		piece("Rail", Vector3.new(30, 2.2, 1.6), Vector3.new(0, 1.1, 0)),
		piece("Rail", Vector3.new(30, 2.2, 1.6), Vector3.new(0, 3.9, 0)),
		piece("RailGap", Vector3.new(30, 0.6, 1.6), Vector3.new(0, 2.5, 0), 1),
		piece("Post", Vector3.new(1.6, 5.8, 1.6), Vector3.new(-15, 2.9, 0)),
		piece("Post", Vector3.new(1.6, 5.8, 1.6), Vector3.new(0, 2.9, 0)),
		piece("Post", Vector3.new(1.6, 5.8, 1.6), Vector3.new(15, 2.9, 0)),
	}
	local function snapshot()
		local rows = {}
		for _, part in ipairs(pieces) do
			table.insert(rows, table.concat({ tostring(part.Size), tostring(part.CFrame), tostring(part.CanCollide),
				tostring(part.CanQuery), tostring(part.CanTouch), tostring(part.Transparency), part.Name }, "|"))
		end
		return table.concat(rows, "\n")
	end
	local shape = snapshot()
	local sameShape, decorOk, tiers, why = true, true, {}, ""
	for n = 0, 8 do
		local t = Service.DressFence(fencePlot, n)
		table.insert(tiers, t)
		if snapshot() ~= shape then
			sameShape = false
		end
		local decor = fencePlot:FindFirstChild(CFG.Fence.FolderName)
		local style = Rebirth.fence(n).style
		if style.Cap then
			local count = 0
			for _, d in ipairs(decor and decor:GetChildren() or {}) do
				count += 1
				if d.CanCollide or d.CanQuery or d.CanTouch or not d.Anchored then
					decorOk, why = false, "a cap can be touched at " .. n
				end
			end
			if count < 3 then
				decorOk, why = false, "too few caps at " .. n
			end
		elseif decor then
			decorOk, why = false, "caps on the wood"
		end
		if hex(pieces[1].Color) ~= hex(style.Colour) or pieces[4].Material ~= style.Material
			or hex(pieces[3].Color) ~= hex(wood) or fencePlot:GetAttribute("FenceTier") ~= t then
			decorOk, why = false, "paint at " .. n
		end
	end
	check(sameShape, "every board, the gap filler and every post keep their size, place, collision and query at every tier")
	check(decorOk and table.concat(tiers, ",") == "0,1,2,3,4,5,6,6,6",
		"each tier repaints only the boards and posts and adds caps nothing can touch, stand on or hit; the gap "
			.. "filler is never repainted", why .. " " .. table.concat(tiers, ","))
	Service.DressFence(fencePlot, 0)
	check(fencePlot:FindFirstChild(CFG.Fence.FolderName) == nil and hex(pieces[1].Color) == hex(wood)
		and pieces[1].Material == Enum.Material.Wood,
		"and back to the plain wood for an owner never reborn (a released plot)")

	--==========================================================================
	say("8. The wiring")
	--==========================================================================
	local economy = sourceOf(Server, "EconomyService")
	check(has(economy, "* GameConfig.rebirthIncomeFor(profile and (profile :: any).Rebirths)")
			and has(economy, "return withPass(player, rate) * temporaryBoost(player) * WeatherService.IncomeFactor()")
			and has(economy, "local paid = math.floor(withPass(player, cash))"),
		"the income bonus rides with the x2 pass: the live garden and the offline claim, never a sale")
	local config = sourceOf(Shared, "GameConfig")
	local offline = sourceOf(Scripts, "OfflineUI")
	check(has(config, "return GameConfig.cashMultiplier(player) * GameConfig.rebirthIncomeOf(player)")
			and has(offline, "return math.floor(pendingBase() * multiplier() * GameConfig.rebirthIncomeOf(player))")
			and select(2, string.gsub(offline, "countTo%(claimed%(%)%)", "")) == 2,
		"and every display of it: the income multiplier and the offline card's amount")
	local store = sourceOf(Server, "StoreService")
	check(has(store, "decidingFor[player] = (decidingFor[player] or 0) + 1")
			and has(store, "function StoreService.Deciding(player: Player): boolean"),
		"a receipt being decided blocks a rebirth (a cash pack is never wiped mid-grant)")
	local ownerTitle = sourceOf(Server, "OwnerTitleService")
	local ownerUI = sourceOf(Scripts, "OwnerTitleUI")
	check(has(ownerTitle, "GameConfig.ownerTitleLift(head:FindFirstChild(GameConfig.Rebirth.Title.Name) ~= nil)")
			and has(ownerUI, "for _, tag in ipairs({ TITLE.Tag, GameConfig.Rebirth.Title.Tag }) do"),
		"ADMIN stacks over a rebirth title whichever came first; the top title turns and hides under a trap like ADMIN")
	check(has(ownerUI, "return GameConfig.rebirthTitleScale(viewport, touch), GameConfig.ownerTitleScale(viewport, touch)")
			and has(ownerUI, "local box, words, sub = GameConfig.rebirthTitleLook(scale)")
			and has(ownerUI, "local look = GameConfig.ownerTitleLook(adminScale)")
			and has(ownerUI, "fitWord(gui:FindFirstChild(\"Glow\"), look.text, look.glow)")
			and has(ownerUI, "fitWord(gui:FindFirstChild(\"Letters\"), look.text, look.edge)")
			and has(ownerUI, "local lift = Vector2.new(0, GameConfig.ownerTitleLift(stacked, scale, adminScale))")
			and has(ownerUI, "\t\t\t\tplace(gui, scale, adminScale)") and has(ownerUI, "\tplace(instance, scale, adminScale)"),
		"each screen redraws the rebirth titles and ADMIN at its own size (smaller on a phone) and keeps ADMIN over the title")
	local ui = sourceOf(Scripts, "RebirthUI")
	check(has(ui, 'r:FireServer(CFG.Action, "confirm", { token = q.token })') and has(ui, "button.set(WORDS.Confirm)")
			and has(ui, "MenuKit.studdedTheme(CFG.Look)") and has(ui, "FloatingSign.new({")
			and not has(ui, "AddCash") and not has(ui, "SetMillTier")
			and select(2, string.gsub(ui, "FireServer%(", "")) == 1,
		"the panel: the Rebirth band, ARE YOU SURE? before the token goes back, the words over the shrine; it sends "
			.. "nothing else")

	--==========================================================================
	say("9. The shrine's ground")
	--==========================================================================
	local at = CFG.Position
	local function apart(x, z)
		return Vector2.new(at.X - x, at.Z - z).Magnitude
	end
	-- The hub's prompts and their reaches (configs; Marigold, the boards and
	-- the plot and mill signs measured in Play, 2026-10-08).
	local prompts = {
		{ "the sacrifice pedestal", GameConfig.Sacrifice.Position.X, GameConfig.Sacrifice.Position.Z, 10 },
		{ "the invite pedestal", GameConfig.InviteRewards.Position.X, GameConfig.InviteRewards.Position.Z, 10 },
		{ "the bonus chest", GameConfig.BonusChest.Position.X, GameConfig.BonusChest.Position.Z, 10 },
		{ "the wheel", 0, 44.3, WheelData.Place.PromptDistance },
		{ "Marigold", -1.8, 21.3, GameConfig.Weapon.PromptDistance },
		{ "SELL ALL", 15.5, 20, 12 },
		{ "SELL ONE", -15.5, 20, 12 },
		{ "plot 04's sign", 31.2, 94, 18 },
		{ "plot 05's sign", 91.8, 37, 18 },
		{ "mill 04's sign", 67.7, 67.8, 18 },
		{ "mill 05's sign", 95.5, -7.7, 18 },
	}
	local worst, worstName = math.huge, ""
	for _, pr in ipairs(prompts) do
		local gap = apart(pr[2], pr[3]) - CFG.PromptDistance - pr[4]
		if gap < worst then
			worst, worstName = gap, pr[1]
		end
	end
	check(worst > 1, "its prompt shares ground with none (each further than the two reaches added)",
		string.format("nearest: %s, %.1f studs to spare", worstName, worst))
	local D = GameConfig.MiniEvent.Dancers
	local function segment(a, b)
		local p2 = Vector2.new(at.X, at.Z)
		local a2, b2 = Vector2.new(a.X, a.Z), Vector2.new(b.X, b.Z)
		local d = b2 - a2
		local t = math.clamp((p2 - a2):Dot(d) / d:Dot(d), 0, 1)
		return (p2 - (a2 + d * t)).Magnitude
	end
	local inWalk = {}
	for _, c in ipairs(D.Corridors) do
		if segment(c.From, c.To) <= c.HalfWidth + 2 then
			table.insert(inWalk, c.Name)
		end
	end
	local listed = false
	for _, k in ipairs(D.KeepClear) do
		if k.Name == "RebirthShrine" and k.At == Vector3.new(at.X, 0, at.Z) then
			listed = true
		end
	end
	check(#inWalk == 0 and listed and at.Magnitude > 46 + 5,
		"off the deck's rim, on no walk to a plot, the obby or the road, and kept clear of the disco's dancers",
		table.concat(inWalk, ", "))

	--==========================================================================
	say("10. The panel on every listed phone and desktop (the owner's phone, 2026-10-08)")
	-- The old body ran off the bottom of a phone panel and took the button with
	-- it. Rebirth.layout -- what RebirthUI places by -- on HudLayoutSpec's
	-- phones (emulated and notched), the owner's 801 x 392, desktops, and each
	-- menu size the player can pick (capped to fit, as UIKit.menuScaleFor does,
	-- and on a phone times its PhoneScale, the panel taking that share: `fill`).
	--==========================================================================
	local HudLayout = require(Shared.HudLayout)
	local TOPBAR, BAR_LEFT = 58, 208
	local function screen(w, h, touch, side, bottom)
		side, bottom = side or 0, bottom or 0
		return {
			safe = Vector2.new(w - side * 2, h - TOPBAR - bottom),
			touch = touch,
			keyboard = not touch,
			viewport = Vector2.new(w, h),
			topbar = HudLayout.rect(BAR_LEFT, 0, w - BAR_LEFT, TOPBAR),
			insetTop = TOPBAR,
		}
	end
	local SCREENS = {
		{ 640, 480, true }, { 772, 360, true }, { 874, 402, true }, { 896, 414, true }, { 956, 440, true },
		{ 1000, 609, true }, { 705, 338, true }, { 640, 360, true }, { 801, 392, true },
		{ 874, 402, true, 62, 21 }, { 956, 440, true, 62, 21 }, { 896, 414, true, 48, 21 }, { 844, 390, true, 47, 21 },
		{ 1063, 716, false }, { 1167, 716, false }, { 1280, 720, false }, { 1920, 1080, false },
	}
	-- UIKit.menuScaleFor's answer: the chosen size times a phone's PhoneScale (1
	-- off a phone), capped to fit 90% x 86% of the safe area at the gui's 300 x
	-- 220 minimum, never below the phone's own scale.
	local function menuScale(input, option): (number, number)
		local phoneScale = GameConfig.menuPhoneScale(input.viewport, input.touch)
		return math.max(phoneScale, math.min(option.Scale * phoneScale, input.safe.X * 0.9 / 300,
			input.safe.Y * 0.86 / 220)), phoneScale
	end
	local bad, seen, phones, keptRoom = {}, 0, 0, {}
	for _, s in ipairs(SCREENS) do
		for _, option in ipairs(GameConfig.MenuSize.Options) do
			seen += 1
			local input = screen(s[1], s[2], s[3], s[4], s[5])
			local hud = HudLayout.solve(input)
			local k, phoneScale = menuScale(input, option)
			local safe = input.safe / k
			local L = Rebirth.layout({ safe = safe, compact = hud.compact, railRight = hud.railRight / k,
				rightLeft = hud.rightLeft / k, fill = math.min(1, k) } :: any, GameConfig.Rail.OutlineThickness)
			-- A phone's panel at NORMAL keeps the room it had at 1:1 -- the same
			-- layout, drawn PhoneScale times as big -- and centred.
			if phoneScale < 1 and option.Id == GameConfig.MenuSize.Default and L.panel.covers then
				phones += 1
				local one = Rebirth.layout({ safe = input.safe, compact = hud.compact, railRight = hud.railRight,
					rightLeft = hud.rightLeft } :: any, GameConfig.Rail.OutlineThickness)
				local p, q = L.panel.rect, one.panel.rect
				-- MenuLayout floors the panel's x and width: up to 1.5 off the centre.
				local offCentre = (p.x + p.w / 2) - safe.X / 2
				if math.abs(p.w - q.w) > 1 or math.abs(p.h - q.h) > 1 or math.abs(offCentre) > 1.5
					or L.wide ~= one.wide then
					table.insert(keptRoom, string.format("%dx%d%s: %.0fx%.0f at x%.2f, %.0fx%.0f at 1:1, %.1f off centre",
						s[1], s[2], if s[4] then " notched" else "", p.w, p.h, k, q.w, q.h, offCentre))
				end
			end
			local p, shell = L.panel.rect, L.panel.shell
			local tag = string.format("%dx%d%s x%.2f", s[1], s[2], if s[4] then " notched" else "", k)
			if p.x < -0.01 or p.y < -0.01 or p.x + p.w > safe.X + 0.01 or p.y + p.h > safe.Y + 0.01 then
				table.insert(bad, tag .. ": panel outside the safe area")
			elseif L.button.x < 0 or L.button.y < 0 or L.button.x + L.button.w > shell.X + 0.01
				or L.button.y + L.button.h > shell.Y + 0.01 then
				table.insert(bad, tag .. ": button outside the panel")
			elseif L.scroll.y + L.scroll.h > L.foot.y + 0.01 or L.scroll.h < CFG.Layout.MinScroll then
				table.insert(bad, tag .. ": the scroll runs into the foot")
			elseif not L.panel.covers and (p.x < hud.railRight / k - 0.01 or p.x + p.w > hud.rightLeft / k + 0.01) then
				table.insert(bad, tag .. ": half over a HUD column")
			elseif L.help.x < 0 or L.help.x + L.help.w > L.close.x + 0.01 or L.help.y < -0.01
				or L.close.x + L.close.w > shell.X + 0.01 or L.help.y + L.help.h > L.panel.header + 0.01 then
				table.insert(bad, tag .. ": the ? or the X outside the band")
			elseif L.back.x < 0 or L.back.y < 0 or L.list.y + L.list.h > shell.Y + 0.01
				or L.list.h < CFG.Layout.TitleRow or L.list.x + L.list.w > shell.X + 0.01 then
				table.insert(bad, tag .. ": the TITLES view outside the panel, or not one row tall")
			end
		end
	end
	check(#bad == 0 and seen == #SCREENS * #GameConfig.MenuSize.Options,
		"on every listed phone (notched too), the owner's 801 x 392 and the desktops, at every menu size: the panel "
			.. "inside the safe area, the button inside the panel under the scroll, never half over a HUD column",
		table.concat(bad, "; "))
	check(phones >= 10 and #keptRoom == 0,
		"on a phone (85%, 2026-10-08) the panel keeps the room it had at 1:1 -- the same layout, two columns where "
			.. "there were two -- drawn smaller and centred",
		string.format("%d phone screen(s); %s", phones, table.concat(keptRoom, "; ")))
	local ownerScale = GameConfig.menuPhoneScale(Vector2.new(801, 392), true)
	local phone = Rebirth.layout({ safe = Vector2.new(801, 392 - TOPBAR) / ownerScale, compact = true, railRight = 0,
		rightLeft = 801 / ownerScale, fill = math.min(1, ownerScale) } :: any, GameConfig.Rail.OutlineThickness)
	-- Landscape phones are wide: the two columns sit side by side there too,
	-- which halves what has to scroll on a short screen.
	check(ownerScale < 1 and phone.panel.covers and phone.wide and phone.scroll.h >= CFG.Layout.MinScroll
			and phone.foot.y + phone.foot.h <= phone.panel.shell.Y + 0.01,
		"on the owner's phone (drawn at 85%): over the rail layer like the Shop, two columns that scroll, the button "
			.. "under them",
		string.format("x%.2f: scroll %.0f tall, foot at %.0f of %.0f", ownerScale, phone.scroll.h, phone.foot.y,
			phone.panel.shell.Y))
	local reworked = sourceOf(Scripts, "RebirthUI")
	check(has(reworked, "local L = Rebirth.layout({") and has(reworked, "scroll.CanvasSize = UDim2.fromOffset(")
			and has(reworked, 'button.hit.Position = UDim2.fromOffset(L.button.x - L.foot.x + L.button.w * 0.5, L.button.y - L.foot.y)')
			and not has(reworked, "TextScaled = true\n\tlocal fit = Instance.new(\"UITextSizeConstraint\")\n\tfit.MaxTextSize = 32"),
		"RebirthUI places by it: the body in a scroll, the foot and its button pinned under it")
	check(has(reworked, "rightLeft = hud.rightLeft / f,\n\t\t-- A phone draws this gui smaller (UIKit.menuScaleFor): the panel keeps its room.\n\t\tfill = math.min(1, k),")
			and has(reworked, "setTurning(true)\n\t\t-- Every open starts at the top of the body: the title strip first.\n\t\tscroll.CanvasPosition = Vector2.new()"),
		"RebirthUI passes a phone's share (fill), and every open starts at the top of the body")

	--==========================================================================
	say("11. The reworked body (the owner: \"add more detail on the rebirth info\")")
	--==========================================================================
	check(has(reworked, "local mill = MillModel.Build(CFG.MinMillTier, CFrame.new(), holder)")
			and has(reworked, "CollectionService:RemoveTag(d, tag)")
			and has(reworked, 'local world = Instance.new("WorldModel")')
			and has(reworked, "local sample = FenceStyle.segment(rebirths + 1, CFG.Preview.FenceLength)")
			and has(reworked, "local still = StatusText.reducedMotion()") and has(reworked, "if not still then")
			and has(reworked, "setTurning(false)\n\t\tclearPictures()"),
		"the REAL required mill and the next fence, live in ViewportFrames: built detached on open with every tag "
			.. "taken off, turning (still for reduced motion), destroyed on close")
	local artIds = true
	for _, key in ipairs({ "Emblem", "Mill", "CashReset", "TitleBadge" }) do
		local id = CFG.Art[key]
		artIds = artIds and type(id) == "string" and (id == "" or string.match(id, "^rbxassetid://%d+$") ~= nil)
	end
	check(artIds and CFG.Art.Emblem == "rbxassetid://133554119533442"
			and CFG.Art.CashReset == "rbxassetid://112687292855232"
			and CFG.Art.TitleBadge == "rbxassetid://133032357694764" and CFG.Art.Mill == ""
			and CFG.Art.CropOffset == Vector2.new(72, 72) and CFG.Art.CropSize == Vector2.new(368, 368)
			and has(reworked, 'if type(id) == "string" and id ~= "" then') and has(reworked, 'if ART.Emblem ~= "" then')
			and has(reworked, "return mark(parent, name, size, z, colour, glyph)")
			and #CFG.Keep == 9 and #CFG.Lose == 2,
		"the owner's three icons (2026-10-08) by their own ids, cropped to one square round all three; no MILL icon, "
			.. "so its drawn stand-in stays (never another upload); nine KEEP chips, two LOSE chips")
	local missing = {}
	for _, item in ipairs(CFG.Keep) do
		if item.Icon then
			local node = GameConfig
			for key in string.gmatch(item.Icon, "[^%.]+") do
				node = type(node) == "table" and node[key] or nil
			end
			if type(node) ~= "string" or node == "" then
				table.insert(missing, item.Icon)
			end
		end
	end
	check(#missing == 0, "every KEEP chip's icon is one the game already has", table.concat(missing, ", "))
	local FenceStyle = require(Shared.FenceStyle)
	local sampleOk = true
	for n = 0, 8 do
		local sample = FenceStyle.segment(n, CFG.Preview.FenceLength)
		for _, d in ipairs(sample:GetDescendants()) do
			if d:IsA("BasePart") and (d.CanCollide or d.CanQuery or d.CanTouch) then
				sampleOk = false
			end
		end
		local rail = sample:FindFirstChild("Rail")
		if not rail or hex(rail.Color) ~= hex(Rebirth.fence(n).style.Colour) then
			sampleOk = false
		end
		sample:Destroy()
	end
	local mapSrc = sourceOf(Server, "MapService")
	check(sampleOk and has(mapSrc, "local BOARDS = { { 1.1, 2.2 }, { 3.9, 2.2 } }") and has(mapSrc, "local FENCE_THICK = 1.6")
			and has(mapSrc, "local FENCE_TOP = 5.0") and FenceStyle.Top == 5.0 and FenceStyle.Thick == 1.6,
		"the fence sample is the real fence's measurements in each tier's paint, and nothing in it can be touched")
	check(has(sourceOf(Server, "RebirthService"), "local tier, capped = FenceStyle.dress(rails, posts, folder, rebirths)"),
		"and the plot's fence is dressed by the same FenceStyle, so the picture is what the plot will wear")

	--==========================================================================
	say("12. The \"?\" and the TITLES view (the owner: \"i want players to see the titles inside a question mark "
		.. "button inside the rebirth ui\")")
	--==========================================================================
	check(has(reworked, "help.Parent = menu.titleBar") and has(reworked, "help.Position = UDim2.new(1, -(touch + CFG.Layout.HelpGap), 0.5, 0)")
			and has(reworked, "t.Image = GameConfig.StuddedLook.Texture") and has(reworked, "helpGlyph.Text = WORDS.Help"),
		"a round, studded, blue \"?\" in the band, left of the X")
	check(has(reworked, "for i, step in ipairs(CFG.Title.Ladder) do") and has(reworked, "local rows, highest, nextIndex = Rebirth.ladder(rebirths)")
			and has(reworked, "WORDS.Reached elseif state == \"next\" then WORDS.NextChip else WORDS.Locked")
			and has(reworked, "string.format(WORDS.RowBonus, Rebirth.times(Rebirth.training(step.At)),"),
		"one row per step: its word in its colour, its rebirth, its training and income, and REACHED / NEXT / LOCKED")
	check(has(reworked, "list.CanvasPosition = Vector2.new(0, math.max(0, rowY - (view - CFG.Layout.TitleRow) * 0.5) * k)")
			and has(reworked, "showTitles(false)") and has(reworked, "back.hit.Activated:Connect(function()")
			and has(reworked, "if r.rainbow then"),
		"opening it brings the NEXT row into view; BACK and closing return to the body; GAIA's rainbow turns, still "
			.. "for reduced motion")

	--==========================================================================
	say("13. Roman numerals (the owner: \"Add roman numerals so that players wont think it's repepitive\")")
	--==========================================================================
	-- An independent roman, digit by digit from fixed tables.
	local ONES = { "", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX" }
	local TENS = { "", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC" }
	local HUNDREDS = { "", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM" }
	local THOUSANDS = { "", "M", "MM", "MMM" }
	local romanBad = {}
	for n = 1, 3999 do
		local want = THOUSANDS[n // 1000 + 1] .. HUNDREDS[(n // 100) % 10 + 1] .. TENS[(n // 10) % 10 + 1]
			.. ONES[n % 10 + 1]
		if Rebirth.roman(n) ~= want and #romanBad < 5 then
			table.insert(romanBad, string.format("%d: %s, not %s", n, Rebirth.roman(n), want))
		end
	end
	check(#romanBad == 0 and Rebirth.roman(0) == "" and Rebirth.roman(-3) == "" and Rebirth.roman(4000) == "4000"
			and Rebirth.roman(1e9) == "1000000000" and Rebirth.roman(14.7) == "XIV",
		"roman numerals I to MMMCMXCIX, each the standard way (IV, IX, XL, XC, CD, CM); past 3999 the plain number",
		table.concat(romanBad, "; "))
	local function wears(n)
		return (Rebirth.titleFor(n)) or "-"
	end
	local CASES = {
		{ 0, "-" }, { 1, "SPROUT" }, { 2, "SEEDLING" }, { 3, "GARDENER" }, { 4, "GREEN THUMB" },
		{ 5, "BOTANIST I" }, { 6, "BOTANIST II" }, { 7, "HERBALIST I" }, { 9, "HERBALIST III" },
		{ 10, "GROVE KEEPER I" }, { 14, "GROVE KEEPER V" }, { 15, "BLOOM WARDEN I" }, { 29, "ELDER ROOT V" },
		{ 30, "CANOPY LORD I" }, { 39, "CANOPY LORD X" }, { 49, "ANCIENT OAK X" }, { 50, "WORLD TREE I" },
		{ 74, "WORLD TREE XXV" }, { 75, "EVERBLOOM I" }, { 99, "EVERBLOOM XXV" }, { 100, "GAIA I" },
		{ 101, "GAIA II" }, { 187, "GAIA LXXXVIII" }, { 1099, "GAIA M" }, { 4098, "GAIA MMMCMXCIX" },
		{ 4099, "GAIA 4000" },
	}
	local wrongTitles = {}
	for _, c in ipairs(CASES) do
		if wears(c[1]) ~= c[2] then
			table.insert(wrongTitles, string.format("%d: %s", c[1], wears(c[1])))
		end
	end
	check(#wrongTitles == 0,
		"BOTANIST I at 5 and II at 6, GROVE KEEPER I to V for 10 to 14, WORLD TREE I to XXV, GAIA I at 100 and on "
			.. "(LXXXVIII at 187, M at 1099); SPROUT to GREEN THUMB, one rebirth each, carry none",
		table.concat(wrongTitles, "; "))
	local repeats = {}
	for n = 2, 5000 do
		if wears(n) == wears(n - 1) and #repeats < 5 then
			table.insert(repeats, tostring(n))
		end
	end
	local stepsOk = true
	for i, step in ipairs(TITLE.Ladder) do
		local first, last = Rebirth.span(i)
		if last == first then
			stepsOk = stepsOk and wears(first) == step.Text
		else
			stepsOk = stepsOk and wears(first) == step.Text .. " I"
				and (last == nil or wears(last) == step.Text .. " " .. Rebirth.roman(last - first + 1))
		end
	end
	check(#repeats == 0 and stepsOk,
		"no two rebirths in a row wear the same title (2 to 5000); every longer step starts at I and ends at its length",
		table.concat(repeats, ","))
	local function rowWords(i)
		local a, b = Rebirth.stepWords(i)
		return a .. " / " .. b
	end
	check(rowWords(1) == "SPROUT / REBIRTH 1" and rowWords(4) == "GREEN THUMB / REBIRTH 4"
			and rowWords(5) == "BOTANIST I-II / REBIRTH 5-6" and rowWords(7) == "GROVE KEEPER I-V / REBIRTH 10-14"
			and rowWords(13) == "WORLD TREE I-XXV / REBIRTH 50-74" and rowWords(15) == "GAIA I+ / REBIRTH 100+",
		"the TITLES list names each step's range: BOTANIST I-II for rebirths 5-6, GAIA I+ from 100",
		rowWords(5) .. "; " .. rowWords(15))

	-- The fit, measured in the fonts the game draws with.
	local TextService = game:GetService("TextService")
	local function wide(text, size)
		return TextService:GetTextSize(text, size, Enum.Font.FredokaOne, Vector2.new(20000, 1000)).X
	end
	local widest, widestText = 0, ""
	for n = 1, 4200 do
		local w = wide(wears(n), TITLE.TextSize)
		if w > widest then
			widest, widestText = w, wears(n)
		end
	end
	-- RebirthService outlines the words 3 px.
	check(widest + 6 <= TITLE.Size.X and wide(wears(1e9), TITLE.TextSize) + 6 <= TITLE.Size.X,
		"every title over a head, to rebirth 4200 and far past it, fits its billboard at full size with its outline",
		string.format("widest %s, %d px of %d", widestText, widest, TITLE.Size.X))
	-- SMALLER (2026-10-09, the owner: "make the title smaller, it looks huge
	-- specially on phones"): under the old 320 x 46 at 28 / 14 everywhere, three
	-- quarters again on a phone, REBIRTH N never under its floor.
	local deskBox, deskWords, deskSub = GameConfig.rebirthTitleLook(1)
	local phoneBox, phoneWords, phoneSub = GameConfig.rebirthTitleLook(TITLE.PhoneScale)
	check(TITLE.TextSize <= 20 and TITLE.SubTextSize <= 12 and TITLE.Size.X <= 240 and TITLE.Size.Y <= 36
			and deskBox == TITLE.Size and deskWords == TITLE.TextSize and deskSub == TITLE.SubTextSize,
		"smaller everywhere: at most 240 x 36, the words at 20 and REBIRTH N at 12 (it was 320 x 46, 28 and 14)")
	check(GameConfig.rebirthTitleScale(Vector2.new(705, 338), true) == 0.75
			and GameConfig.rebirthTitleScale(Vector2.new(338, 705), true) == 0.75
			and GameConfig.rebirthTitleScale(Vector2.new(1024, 768), true) == 1
			and GameConfig.rebirthTitleScale(Vector2.new(705, 338), false) == 1
			and GameConfig.rebirthTitleScale(nil, true) == 1,
		"a phone (touch, its shorter side under 500) draws it at three quarters; a tablet, a desktop, an unknown screen at 1")
	local phoneWidest = 0
	for n = 1, 4200 do
		phoneWidest = math.max(phoneWidest, wide(wears(n), phoneWords))
	end
	check(phoneWords == TITLE.TextSize * 0.75 and phoneSub == math.max(TITLE.SubTextSize * 0.75, TITLE.SubMinTextSize)
			and phoneSub >= 10 and phoneBox.X <= TITLE.Size.X * 0.75 + 0.5 and phoneBox.Y <= TITLE.Size.Y * 0.75 + 0.5
			and phoneWidest + 6 <= phoneBox.X and phoneWords <= phoneBox.Y * 0.6 and phoneSub <= phoneBox.Y * 0.4
			and deskWords <= deskBox.Y * 0.6 and deskSub <= deskBox.Y * 0.4,
		"on a phone every title still fits with its outline, the words and REBIRTH N each in its line, REBIRTH N never under 10",
		string.format("phone %dx%d, words %.1f, REBIRTH N %.1f, widest %d px", phoneBox.X, phoneBox.Y, phoneWords, phoneSub,
			phoneWidest))
	check(Rebirth.fitSize(26, 300, 345) == 26 and Rebirth.fitSize(26, 345, 300) == 22
			and Rebirth.fitSize(26, 100, 0) == 26 and Rebirth.fitSize(16, 1e6, 10) == 1,
		"a line wider than its box is drawn just small enough to fit; one that fits keeps its size")
	-- The panel's narrowest column and TITLES list on every listed screen at
	-- every menu size (a phone's 85% included), by RebirthUI's own measures
	-- (pinned below): the scroll bar 6, 4 more, the gap 10; the strip and the
	-- title line span a column, the title line after its 34 px badge; a row's
	-- words 42% of the row less 12 and the title effects' room (TitleFX.List).
	local column, listW = math.huge, math.huge
	for _, s in ipairs(SCREENS) do
		for _, option in ipairs(GameConfig.MenuSize.Options) do
			local input = screen(s[1], s[2], s[3], s[4], s[5])
			local hud = HudLayout.solve(input)
			local k = menuScale(input, option)
			local L = Rebirth.layout({ safe = input.safe / k, compact = hud.compact, railRight = hud.railRight / k,
				rightLeft = hud.rightLeft / k, fill = math.min(1, k) } :: any, GameConfig.Rail.OutlineThickness)
			local inner = L.scroll.w - 6 - 4
			column = math.min(column, if L.wide then (inner - 10) * 0.5 else inner)
			listW = math.min(listW, L.list.w)
		end
	end
	local FIT = 6
	local small = { strip = math.huge, nextStrip = math.huge, titleLine = math.huge, row = math.huge }
	local smallAt = {}
	local function note(key, size, text)
		if size < small[key] then
			small[key], smallAt[key] = size, text
		end
	end
	for n = 0, 1099 do
		local now = if n == 0 then CFG.Words.NotYet else string.format(CFG.Words.Strip, n, wears(n))
		note("strip", Rebirth.fitSize(26, wide(now, 26), column - FIT), now)
		local after = string.format(CFG.Words.NextStrip, n + 1, wears(n + 1))
		note("nextStrip", Rebirth.fitSize(16, wide(after, 16), column - FIT), after)
		local line = string.format(CFG.Words.TitleLine, wears(n + 1))
		note("titleLine", Rebirth.fitSize(17, wide(line, 17), column - 34 - FIT), line)
	end
	for i in ipairs(TITLE.Ladder) do
		local text = Rebirth.stepWords(i)
		note("row", Rebirth.fitSize(22, wide(text, 22), (listW - 10) * 0.42 - 12 - GameConfig.TitleFX.List.Room - FIT),
			text)
	end
	-- Measured 2026-10-08: column 310, list 541; the strip 20 at worst (REBIRTH
	-- 987 · GAIA DCCCLXXXVIII), the other three never shrink.
	check(small.strip >= 18 and small.nextStrip >= 14 and small.titleLine >= 14 and small.row >= 20,
		"in the panel, on the narrowest column of every listed screen and menu size, to rebirth 1099 (GAIA M): the "
			.. "strip never under 18 px of its 26, the next line and NEXT UNLOCKS' title never under 14, a TITLES row "
			.. "never under 20 of its 22",
		string.format("column %.0f, list %.0f: strip %d (%s), next %d (%s), title %d (%s), row %d (%s)", column, listW,
			small.strip, smallAt.strip, small.nextStrip, smallAt.nextStrip, small.titleLine, smallAt.titleLine,
			small.row, smallAt.row))
	local serviceSrc = sourceOf(Server, "RebirthService")
	check(has(serviceSrc, "local text, step = Rebirth.titleFor(n)") and has(serviceSrc, 'line(gui, "Words", text, step.Colour,')
			and has(reworked, "local nowText, now = Rebirth.titleFor(n)")
			and has(reworked, "local nextText, nextTitle = Rebirth.titleFor(n + 1)")
			and has(reworked, 'string.format(WORDS.TitleLine, nextText or "")')
			and has(reworked, "local stepText, stepRebirths = Rebirth.stepWords(i)")
			and has(reworked, "rebirthWords.Text = stepRebirths")
			and has(reworked, "fitOne(stripNow, 26)") and has(reworked, "fitOne(stripNext, 16)")
			and has(reworked, "fitOne(titleLine, 17)") and has(reworked, "fitOne(word, 22)")
			and has(reworked, "label.TextSize = Rebirth.fitSize(base, need, room)")
			and has(reworked, "local room = label.AbsoluteSize.X / k - FIT_MARGIN") and has(reworked, "local FIT_MARGIN = 6")
			and has(reworked, "scroll.ScrollBarThickness = 6") and has(reworked, "local GAP = 10")
			and has(reworked, "local inner = w - scroll.ScrollBarThickness - 4")
			and has(reworked, "local half = (inner - GAP) * 0.5")
			and has(reworked, "titleLine.Position = UDim2.fromOffset(34, 0)")
			and has(reworked, "word.Size = UDim2.new(0.42, -FX_LEFT, 0, 30)")
			and has(reworked, "local FX_LEFT = 12 + (if fxAny then FX_LIST.Room else 0)"),
		"the title over the head, the strip, NEXT UNLOCKS and the TITLES rows all wear Rebirth.titleFor / stepWords, "
			.. "and each of those lines shrinks to fit its box")
	-- Seen in Play 2026-10-08: on the old filled pink row (the highest reached)
	-- BLOOM WARDEN's pink words all but vanished.
	local plate = Color3.fromRGB(46, 30, 52)
	local worstPlate, worstPlateWord = math.huge, ""
	for _, step in ipairs(TITLE.Ladder) do
		local ratio = (lum(step.Colour) + 0.05) / (lum(plate) + 0.05)
		if ratio < worstPlate then
			worstPlate, worstPlateWord = ratio, step.Text
		end
	end
	check(has(reworked, "local DIM = Color3.fromRGB(46, 30, 52)") and has(reworked, "r.frame.BackgroundColor3 = DIM")
			and has(reworked, 'r.ring.Enabled = i == highest or state == "next"')
			and has(reworked, "ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border")
			and not has(reworked, 'then CFG.Look.Band elseif state == "next" then CFG.Look.Edge else DIM')
			and worstPlate >= 3,
		"every TITLES row keeps the same dark plate -- the highest reached and the next are ringed, never filled -- "
			.. "and every title colour reads on it", string.format("lowest: %s at %.1f:1", worstPlateWord, worstPlate))
end)

scratch:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nRebirthSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
