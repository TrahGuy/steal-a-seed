--!nocheck
--==============================================================================
-- Steal a Seed :: InviteRewardsSpec
--
-- Invite a Friend (2026-10-06), driven end to end without a Play session. Edit
-- mode, through the spec runner (fresh-required modules):
--
--     python store6/spec_direct.py InviteRewardsSpec
--
-- 1. The four rewards: rarity, fixed income at every tier, one size, unsellable,
--    and in no pool, shelf, roll, wheel or event.
-- 2. The count-to-form choice (InviteRewards): 0..50, never ahead of the grant,
--    a jump from 0 to 12 is ONE change to Pharaothorn.
-- 3. What the sign and the panel say, and each card's state, for 0, 1, 4, 5,
--    12, 20 and 50; the badge.
-- 3b. The sign read from the nearest spawn pad: the 20 x 11 plate on the same
--    pillar feet, the far view's letters on a 705 x 338 phone from that pad.
-- 4. No stall buys one: SELL ONE refuses, SELL ALL leaves it, the Bag prices none.
-- 5. Counting and giving, by the REAL InviteService, PlayerDataService,
--    CarryService and ProfileSchema: 1 / 5 / 10 / 20 friends, a duplicate, the
--    inviter themself, a returning player, an inviter in another server (the
--    inbox), a rejoin (nothing given twice), a full Bag (the form waits), and
--    the "!" flag.
-- 6. The rigs: every joint the idle and the walk pose exists; nothing drifts
--    over 600 frames; the walk keeps its feet; the pedestal copy at its scale,
--    filling the room under the sign, its aura's flare clear of the keyline and
--    the pillars, its lights never past 60.
--
-- Stood in: SaveService's Load / Save and its inbox (in-memory tables, so no
-- DataStore is read or written), PlotService's level, the join data and the
-- player lookup (InviteService.Hooks). Players are stand-in tables with real
-- signals, a real Backpack and a real body, as SacrificeSpec builds them.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local InviteRewards = require(Shared.InviteRewards)
local InviteForms = require(Shared.InviteForms)
local PlantIdles = require(Shared.PlantIdles)
local PlantInfo = require(Shared.PlantInfo)
local AlmanacView = require(Shared.AlmanacView)
local WheelData = require(Shared.WheelData)
local HatchRoll = require(Shared.HatchRoll)
local CreatureModel = require(Shared.CreatureModel)
local SecretModel = require(Shared.SecretModel)
local SecretIdle = require(Shared.SecretIdle)
local BiomeData = require(Shared.BiomeData)
local Server = ServerScriptService.SeedGameServer
local SaveService = require(Server.SaveService)
local PlotService = require(Server.PlotService)
local ProfileSchema = require(Server.ProfileSchema)
local PlayerDataService = require(Server.PlayerDataService)
local CarryService = require(Server.CarryService)
local EconomyService = require(Server.EconomyService)
local InviteService = require(Server.InviteService)
local Metrics = require(Server.Metrics)
local InviteSend = require(Shared.InviteSend)
local InviteSounds = require(Shared.InviteSounds)
local Notice = require(Shared.Notice)

local CONFIG = GameConfig.InviteRewards
local A = CONFIG.Attributes
local IDS = { "dustthorn", "thornbrute", "pharaothorn", "heliothorn" }
local OWNER = {
	dustthorn = { "Dustthorn", "Epic", 5000, 1 },
	thornbrute = { "Thornbrute", "Legendary", 25000, 5 },
	pharaothorn = { "Pharaothorn", "Mythic", 75000, 10 },
	heliothorn = { "Heliothorn", "Secret", 175000, 20 },
}

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
local function section(title, fn)
	say("\n-- " .. title .. " --")
	local ran, why = pcall(fn)
	check(ran, title .. ": ran to its end", why)
end
local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

local fixture = Instance.new("Folder")
fixture.Name = "InviteRewardsSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace

--==============================================================================
-- THE STAND-INS
--==============================================================================
local saves, plots, data, carry, invite, metrics = SaveService :: any, PlotService :: any, PlayerDataService :: any,
	CarryService :: any, InviteService :: any, Metrics :: any

local store = {}
local loadAs = {}
saves.Load = function(userId)
	if loadAs[userId] then
		return loadAs[userId], deepCopy(store[userId])
	end
	if store[userId] == nil then
		return "new", nil
	end
	return "ok", deepCopy(store[userId])
end
saves.Save = function(userId, payload)
	store[userId] = deepCopy(payload)
	return true
end
saves.Forget = function() end
-- THE INBOX, IN MEMORY.
local inbox = {}
saves.ReadInbox = function(userId)
	return true, deepCopy(inbox[userId])
end
saves.UpdateInbox = function(userId, transform)
	local result = transform(deepCopy(inbox[userId]))
	if result ~= nil then
		inbox[userId] = deepCopy(result)
	end
	return true
end
plots.SetDesiredLevel = function()
	return true
end
data.RecordTutorial = function() end
metrics.income = function() end
metrics.profileReady = function() end

local byId = {}
invite.Hooks.playerById = function(id)
	return byId[id]
end
-- A returning friend's free spin (2026-10-08), heard: { UserId, ... } in order.
local spinsFor = {}
invite.Hooks.grantSpin = function(p)
	table.insert(spinsFor, p.UserId)
	return 1
end
local joinFor = {}
invite.Hooks.joinData = function(p)
	return joinFor[p]
end
-- DisplayNames: a stand-in's own, else the ones Roblox would give (a table).
local displayNames = {}
invite.Hooks.displayName = function(id)
	local p = byId[id]
	if p then
		return p.DisplayName
	end
	return displayNames[id]
end

local holders = {}
local realMount = data.MountStats
data.MountStats = function(holder, profile)
	return realMount(holders[holder] or holder, profile)
end

local function standIn(name, userId)
	local holder = Instance.new("Folder")
	holder.Name = name
	holder.Parent = fixture
	local childAdded = Instance.new("BindableEvent")
	local characterAdded = Instance.new("BindableEvent")
	local characterRemoving = Instance.new("BindableEvent")
	local attrs = {}
	local p = {
		Name = name,
		DisplayName = name,
		UserId = userId,
		Parent = Players,
		Character = nil,
		ChildAdded = childAdded.Event,
		CharacterAdded = characterAdded.Event,
		CharacterRemoving = characterRemoving.Event,
		_backpack = nil,
		_holder = holder,
		_attrs = attrs,
	}
	function p.SetAttribute(_, k, v)
		attrs[k] = v
	end
	function p.GetAttribute(_, k)
		return attrs[k]
	end
	function p.Kick() end
	function p.FindFirstChildOfClass(self, className)
		local backpack = self._backpack
		if className == "Backpack" and backpack and backpack.Parent then
			return backpack
		end
		return nil
	end
	function p.WaitForChild(_, childName)
		return holder:FindFirstChild(childName)
	end
	holders[p] = holder
	return p
end

-- `noHumanoid`: a body nothing is equipped into. A restored grown plant is
-- equipped on arrival, and a stand-in's Humanoid has no real Backpack to put the
-- previous one back in (HeldRestoreSpec's bodies have none for the same reason).
local function enter(name, userId, noHumanoid)
	local p = standIn(name, userId)
	data.Join(p)
	local deadline = os.clock() + 5
	while not data.IsReady(p) and os.clock() < deadline do
		task.wait()
	end
	local backpack = Instance.new("Backpack")
	backpack.Parent = p._holder
	p._backpack = backpack
	local body = Instance.new("Model")
	body.Name = name .. "Body"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.Parent = body
	if not noHumanoid then
		Instance.new("Humanoid").Parent = body
	end
	body.Parent = p._holder
	p.Character = body
	p._body = body
	carry.WatchHeld(p)
	carry.RestoreHeld(p)
	task.wait(0.3)
	for _, tool in ipairs(body:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Parent = backpack
		end
	end
	byId[userId] = p
	return p
end

local function leave(p)
	byId[p.UserId] = nil
	data.Leave(p)
	p.Parent = nil
	task.wait()
end

local function inviteTools(p)
	local n = {}
	for _, container in ipairs({ p._backpack, p._body }) do
		if container and container.Parent then
			for _, tool in ipairs(container:GetChildren()) do
				local id = tool:GetAttribute("SpeciesId")
				if tool:IsA("Tool") and OWNER[id] then
					n[id] = (n[id] or 0) + 1
				end
			end
		end
	end
	return n
end

local function heldRows(p, id)
	local profile = data.Get(p)
	local n = 0
	for _, row in ipairs(profile and profile.Held or {}) do
		if row.Id == id then
			n += 1
		end
	end
	return n
end

-- `n` new friends for `p`, as joins this server judges.
local nextFriend = 900000
local function friends(p, n)
	for _ = 1, n do
		nextFriend += 1
		invite.Credit(p.UserId, nextFriend)
	end
end

local ok, err = pcall(function()

--==============================================================================
section("1. The four rewards", function()
	for _, id in ipairs(IDS) do
		local sp = SeedData.Get(id)
		local o = OWNER[id]
		check(sp ~= nil and sp.Name == o[1] and sp.Rarity == o[2], id .. ": " .. o[1] .. ", " .. o[2], sp and sp.Rarity)
		local fixed = true
		for tier = 1, SeedData.TierCount do
			fixed = fixed and SeedData.IncomePerSecond(sp, tier) == o[3]
		end
		check(fixed, string.format("%s pays exactly $%d/s at every tier (FixedIncome)", id, o[3]))
		check(SeedData.Unsized(sp) and not SeedData.Sellable(sp) and sp.Invite == true and sp.Carry == "overhead",
			id .. ": one size, unsellable, an invite reward, carried overhead")
		check(GameConfig.RarityColor[sp.Rarity] ~= nil, id .. ": its rarity has the existing colour")
		check(InviteForms.Plants[id] ~= nil and SecretModel.HasPlant(id), id .. ": built from its supplied form")
	end
	check(table.concat(CONFIG.Thresholds, ",") == "1,5,10,20" and table.concat(CONFIG.Forms, ",") == table.concat(IDS, ","),
		"the track: 1 / 5 / 10 / 20 friends -> Dustthorn, Thornbrute, Pharaothorn, Heliothorn")
	-- In no pool, shelf, roll, wheel or event.
	local listed = {}
	for _, sp in ipairs(SeedData.Species) do
		listed[sp.Id] = true
	end
	for _, biome in ipairs(BiomeData.Biomes) do
		for _, sp in ipairs(SeedData.InBiome(biome.Id)) do
			listed[sp.Id] = true
		end
		for _, card in ipairs(AlmanacView.shelf(biome.Id)) do
			local c = card :: any
			listed[tostring(c.Id or c.id or (c.species and c.species.Id) or "")] = true
		end
		for _, sp in ipairs(SeedData.InBiome(biome.Id)) do
			for _, other in ipairs(HatchRoll.candidates(sp.Id)) do
				listed[other] = true
			end
		end
	end
	for _, pool in pairs(WheelData.Pools) do
		for _, id in ipairs(pool) do
			listed[id] = true
		end
	end
	for _, sp in ipairs(SeedData.RainSpecies) do
		listed[sp.Id] = true
	end
	local leaked = {}
	for _, id in ipairs(IDS) do
		if listed[id] then
			table.insert(leaked, id)
		end
		check(SeedData.Get(id).Pod == nil and SeedData.Get(id).Event == nil, id .. ": no pod and no event")
	end
	check(#leaked == 0, "none is in a biome pool, an Index shelf, a wheel pool, the Rain roster or a hatch roll",
		table.concat(leaked, ","))
end)

--==============================================================================
section("2. The count-to-form choice", function()
	local want = { [0] = "dustthorn", [1] = "dustthorn", [4] = "dustthorn", [5] = "thornbrute", [9] = "thornbrute",
		[10] = "pharaothorn", [19] = "pharaothorn", [20] = "heliothorn", [50] = "heliothorn" }
	for _, n in ipairs({ 0, 1, 4, 5, 9, 10, 19, 20, 50 }) do
		check(InviteRewards.formFor(n) == want[n], string.format("%d friend(s) -> %s", n, want[n]), InviteRewards.formFor(n))
	end
	check(InviteRewards.tierFor(0) == 0 and InviteRewards.tierFor(1) == 1 and InviteRewards.tierFor(20) == 4
		and InviteRewards.tierFor(-3) == 0 and InviteRewards.tierFor(0 / 0) == 0 and InviteRewards.tierFor("9") == 0,
		"tiers: 0 at 0, 1 at 1, 4 at 20; junk counts read 0")
	-- Never ahead of the grant, never above the server's count.
	local never = true
	for count = 0, 30 do
		for granted = 0, 6 do
			local shown = InviteRewards.shownTier(count, granted)
			if shown > InviteRewards.tierFor(count) or shown > granted then
				never = false
			end
		end
	end
	check(never, "the shown form never passes the count nor the forms given (31 counts x 7 grants)")
	-- 0 -> 12 at once (an offline credit): one change, to Pharaothorn.
	local before = InviteRewards.content(0, 0).tier
	local after = InviteRewards.content(12, 3).tier
	check(before == 0 and after == 3 and InviteRewards.formOfTier(after) == "pharaothorn",
		"a jump from 0 to 12 friends is one change, 0 -> Pharaothorn")
	check(InviteRewards.content(12, 1).tier == 1, "12 friends with only Dustthorn given still shows Dustthorn")
end)

--==============================================================================
section("3. The sign, the panel's cards and the badge", function()
	local c0 = InviteRewards.content(0, 0)
	check(c0.shown.form == "dustthorn" and c0.nextText == "NEXT: Dustthorn (Epic) at 1 invite" and c0.barText == "0 / 1"
		and c0.fraction == 0 and not c0.final, "0: Dustthorn as the goal, NEXT at 1 invite, 0 / 1", c0.nextText)
	local c1 = InviteRewards.content(1, 1)
	check(c1.shown.form == "dustthorn" and c1.shown.incomeText == "$5K/s" and c1.nextText ==
		"NEXT: Thornbrute (Legendary) at 5 invites" and c1.barText == "1 / 5", "1: Dustthorn $5K/s, NEXT Thornbrute at 5",
		c1.shown.incomeText .. " | " .. tostring(c1.nextText))
	local c4 = InviteRewards.content(4, 1)
	check(c4.barText == "4 / 5" and math.abs(c4.fraction - 0.8) < 1e-9 and c4.fill == GameConfig.RarityColor.Legendary,
		"4: 4 / 5, filled in Legendary's colour")
	local c5 = InviteRewards.content(5, 2)
	check(c5.shown.form == "thornbrute" and c5.barText == "5 / 10", "5: Thornbrute, 5 / 10")
	local c12 = InviteRewards.content(12, 3)
	check(c12.shown.form == "pharaothorn" and c12.barText == "12 / 20" and c12.nextText ==
		"NEXT: Heliothorn (Secret) at 20 invites", "12: Pharaothorn, 12 / 20, NEXT Heliothorn")
	local c20 = InviteRewards.content(20, 4)
	check(c20.final and c20.finalText == "FINAL FORM REACHED" and c20.nextText == nil and c20.fraction == 1
		and c20.fill == CONFIG.Gold, "20: FINAL FORM REACHED, full gold bar, no NEXT")
	local c50 = InviteRewards.content(50, 4)
	check(c50.final and c50.shown.form == "heliothorn" and c50.barText == "50 / 20", "50: still the final form")
	local function states(n, g)
		local s = {}
		for _, card in ipairs(InviteRewards.cards(n, g)) do
			table.insert(s, card.state)
		end
		return table.concat(s, ",")
	end
	check(states(0, 0) == "next,locked,locked,locked", "cards at 0: NEXT, then three LOCKED", states(0, 0))
	check(states(1, 1) == "earned,next,locked,locked", "cards at 1", states(1, 1))
	check(states(4, 1) == "earned,next,locked,locked", "cards at 4", states(4, 1))
	check(states(5, 2) == "earned,earned,next,locked", "cards at 5", states(5, 2))
	check(states(12, 3) == "earned,earned,earned,next", "cards at 12", states(12, 3))
	check(states(20, 4) == "earned,earned,earned,earned", "cards at 20", states(20, 4))
	check(states(50, 4) == "earned,earned,earned,earned", "cards at 50", states(50, 4))
	local cards = InviteRewards.cards(0, 0)
	check(cards[4].gold and not cards[1].gold and cards[4].at == 20 and cards[2].incomeText == "$25K/s",
		"Heliothorn's card is gold at every state; each card says its threshold and rate")
	check(InviteRewards.badge(nil) and InviteRewards.badge(false) and not InviteRewards.badge(true),
		"the \"!\" shows until the panel is seen")
	-- THE TRACK WITH THE WHEEL (2026-10-08): the wheel and the milestones both
	-- give the first plant not owned, so every screen names the plant each
	-- milestone really gives. With nothing won on the wheel: exactly as before.
	local F = CONFIG.Forms
	local function ownedOf(...)
		local set = {}
		for _, form in ipairs({ ... }) do
			set[form] = true
		end
		return set
	end
	local function track(n, g, owned)
		local s = {}
		for _, card in ipairs(InviteRewards.cards(n, g, owned)) do
			table.insert(s, string.format("%s:%s:%s", card.form, card.state, if card.won then "owned" else tostring(card.at)))
		end
		return table.concat(s, ",")
	end
	local same = true
	for n = 0, 25 do
		local g = InviteRewards.tierFor(n)
		local given = {}
		for i = 1, g do
			given[F[i]] = true
		end
		local a, b = InviteRewards.content(n, g), InviteRewards.content(n, g, given)
		if a.shown.form ~= b.shown.form or a.nextText ~= b.nextText or a.barText ~= b.barText or a.final ~= b.final
			or track(n, g) ~= track(n, g, given) then
			same = false
		end
	end
	check(same, "nothing won on the wheel: the sign, the panel and the cards say exactly what they said (26 counts)")
	-- The wheel gave Dustthorn before any friend joined.
	local w0 = InviteRewards.content(0, 0, ownedOf(F[1]))
	check(w0.shown.form == F[1] and w0.next ~= nil and w0.next.form == F[2] and w0.next.at == 1
			and w0.nextText == "NEXT: Thornbrute (Legendary) at 1 invite" and w0.barText == "0 / 1",
		"Dustthorn won on the wheel at 0 friends: NEXT is Thornbrute at 1 invite", w0.nextText)
	local t0 = track(0, 0, ownedOf(F[1]))
	check(t0 == string.format("%s:earned:owned,%s:next:1,%s:locked:5,%s:locked:10", F[1], F[2], F[3], F[4]),
		"its cards: Dustthorn owned; Thornbrute at 1 invite, Pharaothorn at 5, Heliothorn at 10", t0)
	-- ... then its first friend's milestone gave Thornbrute (the guarded Play's state).
	local w1 = InviteRewards.content(1, 1, ownedOf(F[1], F[2]))
	check(w1.shown.form == F[2] and w1.nextText == "NEXT: Pharaothorn (Mythic) at 5 invites" and w1.barText == "1 / 5",
		"then 1 friend gave Thornbrute: it stands, NEXT is Pharaothorn at 5 invites", w1.nextText)
	local t1 = track(1, 1, ownedOf(F[1], F[2]))
	check(t1 == string.format("%s:earned:owned,%s:earned:owned,%s:next:5,%s:locked:10", F[1], F[2], F[3], F[4]),
		"its cards: two owned (which milestone gave which is not said), Pharaothorn at 5, Heliothorn at 10", t1)
	-- Every plant owned before the last milestone: the track is complete.
	local wAll = InviteRewards.content(10, 3, ownedOf(F[1], F[2], F[3], F[4]))
	check(wAll.final and wAll.nextText == nil and wAll.shown.form == F[4] and wAll.fraction == 1,
		"every plant owned at 10 friends: FINAL, Heliothorn stands, no NEXT")
	-- The reward card names the plant the server gave, not the tier's own.
	local given1 = InviteRewards.popup(1, F[2])
	local plain1 = InviteRewards.popup(1)
	check(given1.form == F[2] and given1.name == "Thornbrute" and given1.line == plain1.line and plain1.form == F[1]
			and InviteRewards.reward(2, "not-a-form").form == F[2],
		"the reward card shows the plant given (Thornbrute at 1 friend), its line still the tier's; a stray form is ignored",
		given1.name .. " / " .. given1.line)
	-- The three screens read the owned set; the card reads the payload's form.
	local function src(name)
		local found = game:GetService("StarterPlayer"):FindFirstChild(name, true)
		local ok, text = pcall(function()
			return found.Source
		end)
		return if ok and type(text) == "string" then text else ""
	end
	local ui, hub, card = src("InviteUI"), src("InviteHub"), src("InviteRewardUI")
	local function has(text, needle)
		return string.find(text, needle, 1, true) ~= nil
	end
	check(has(ui, "InviteRewards.content(count, granted, owned)") and has(ui, "if c.won then WORDS.Owned")
			and has(hub, "InviteRewards.content(count, granted, InviteRewards.ownedSet(player:GetAttribute(A.Owned)))")
			and has(hub, "player:GetAttributeChangedSignal(A.Owned):Connect(refresh)")
			and has(card, "InviteRewards.popup(tier, givenForm[tier])")
			and has(card, "givenForm[math.floor(tonumber(payload.tier) or 0)] = payload.form"),
		"wired: the panel and the sign pass the owned set, the pedestal follows it, the card shows the plant given")
end)

--==============================================================================
-- 3b. THE SIGN FROM THE NEAREST SPAWN PAD (the owner, 2026-10-06: a bigger
-- plate and a far view). Measured, not judged: the nearest spawn pad in the
-- map, its follow camera (12.5 studs behind the player toward the sign, 7 up),
-- a 705 x 338 phone at the camera's 70-degree field of view, and how far off
-- the plate's face that camera sees it.
--==============================================================================
section("3b. The sign, read from the nearest spawn pad", function()
	local S = CONFIG.Sign
	local W = CONFIG.Words
	local TextService = game:GetService("TextService")
	local function sourceOf(parent, name)
		local found = parent:FindFirstChild(name, true)
		local ok, src = pcall(function()
			return found.Source
		end)
		return if ok and type(src) == "string" then src else ""
	end
	check(S.Width == 20 and S.Height == 11 and S.Bottom == 14.2 and S.PillarHalf == 14 / 2 + S.PillarWidth / 2,
		"the plate 20 x 11, its foot where it was; the pillars' feet where they stood beside the 14-stud plate")
	local svc = sourceOf(ServerScriptService, "InviteService")
	check(string.find(svc, "local half = S.PillarHalf", 1, true) ~= nil
			and string.find(svc, "local pillarH = S.Bottom - S.Keyline", 1, true) ~= nil,
		"the pillars end under the plate's keyline: the plate rests on them, nothing new on the ground")
	-- The far words at TextScaled's top (100 px) on this canvas, in studs.
	local lineH = (S.Height * S.PixelsPerStud - S.FarPad * 2) / #W.SignFar
	local room = S.Width * S.PixelsPerStud - S.FarPad * 2
	local font, letter = 100, math.huge
	for _, word in ipairs(W.SignFar) do
		local v = TextService:GetTextSize(word, 100, Enum.Font.LuckiestGuy, Vector2.new(100000, 1000))
		font = math.min(font, lineH, 100 * room / v.X)
		letter = math.min(letter, v.X / #word / 100)
	end
	local em = font / S.PixelsPerStud
	check(table.concat(W.SignFar, " ") == W.Title and font >= 99.5 and em >= 4.9,
		string.format("the far view is the title on two lines at the 100-px top: %.1f-stud letters", em))
	-- The nearest pad and its camera.
	local origin = CFrame.new(CONFIG.Position) * CFrame.Angles(0, math.rad(CONFIG.FacingDegrees), 0)
	local centre = (origin * CFrame.new(0, S.Bottom + S.Height / 2, 0)).Position
	local map = Workspace:FindFirstChild(GameConfig.Map.FolderName)
	local pad, best = nil, math.huge
	for _, d in ipairs(if map then map:GetDescendants() else {}) do
		if d:IsA("BasePart") and d.Name == GameConfig.Plot.SpawnPadName then
			local flat = Vector3.new(centre.X - d.Position.X, 0, centre.Z - d.Position.Z).Magnitude
			if flat < best then
				pad, best = d, flat
			end
		end
	end
	check(pad ~= nil, "the map's spawn pads (the Edit preview) are here to measure from")
	if not pad then
		return
	end
	local toward = Vector3.new(centre.X - pad.Position.X, 0, centre.Z - pad.Position.Z).Unit
	local camera = pad.Position - toward * 12.5 + Vector3.new(0, 7, 0)
	local view = camera - centre
	local dist = view.Magnitude
	local perStud = 338 / (2 * dist * math.tan(math.rad(70) / 2))
	local across = math.abs(Vector3.new(view.X, 0, view.Z).Unit:Dot(origin.LookVector))
	local tall, wide = em * perStud, em * letter * perStud * across
	say(string.format("  %s: its camera %.0f studs off, the plate seen %.0f deg from the side; the far words %.1f px "
		.. "tall, %.1f px a letter (the old plate's title: 2.9 px, 0.8 px a letter)", pad:GetFullName(), dist,
		math.deg(math.acos(across)), tall, wide))
	check(dist > S.FarFrom, "from the nearest pad the far view is the one showing")
	check(tall >= 12 and wide >= 3.5,
		string.format("read from the nearest pad on a 705 x 338 phone: %.1f px tall, %.1f px a letter", tall, wide))
	-- Near, the whole sign, every line Height / 7.4 what it was.
	local grow = S.Height / 7.4
	local nearTitle = 54 * (S.Height * S.PixelsPerStud / 370) / S.PixelsPerStud
	check(grow >= 1.4 and math.abs(nearTitle - 1.08 * grow) < 0.01 and S.FarBand > 0 and S.FarFrom - S.FarBand > 20,
		string.format("near, the whole sign at %.2fx (the title %.2f-stud letters, was 1.08), back under %d studs",
			grow, nearTitle, S.FarFrom - S.FarBand))
	-- The switch, in InviteHub.
	local hub = sourceOf(game:GetService("StarterPlayer"), "InviteHub")
	local function has(needle)
		return string.find(hub, needle, 1, true) ~= nil
	end
	check(has('far.Name = "Far"') and has("if d < S.FarFrom - S.FarBand then") and has("elseif d > S.FarFrom then")
			and has("f.near.Visible = not farNow and not rulesNow") and has("f.far.Visible = farNow")
			and has("local K = H / 370") and has("f.farTrim.Enabled = content.final"),
		"InviteHub: the far view past FarFrom, the whole sign back under FarFrom - FarBand, the gold trim on both")
	check(has("f.rules.Visible = not farNow and rulesNow") and has("rulesTitle.Text = WORDS.RulesTitle")
			and has("for i, line in ipairs(WORDS.Rules) do") and CONFIG.RulesSignSeconds < CONFIG.RulesSignCycle,
		"InviteHub: the rules (who counts, the four plants, a returning friend's spin) in the near view's place "
			.. "for a few seconds of every cycle; never in the far view")
	-- NEXT clear of the bar (the owner, 2026-10-06: in p18b the bar's count rose into it).
	local R = S.Rows
	local function gap(a, b)
		return b[1] - (a[1] + a[2])
	end
	local others = math.max(gap(R.Header, R.Name), gap(R.Name, R.Info), gap(R.Info, R.Next))
	check(gap(R.Next, R.Bar) >= others and R.Count[1] >= 8 and R.Count[1] + R.Count[2] <= R.Bar[2] - 8
			and R.Bar[1] + R.Bar[2] <= 370 - 8 and has("ROWS.Next[1] * K") and has("ROWS.Bar[1] * K")
			and has("ROWS.Count[1] * K"),
		string.format("NEXT stands %d clear of the bar (no other two rows more than %d apart), the count %d inside it",
			gap(R.Next, R.Bar), others, R.Count[1]))
end)

--==============================================================================
section("4. No stall buys one", function()
	local p = enter("Seller", 41001)
	local sp = SeedData.Get("dustthorn")
	local okGive = carry.GiveHatched(p, sp, SeedData.InviteTier, -1, nil, true)
	check(okGive, "an invite plant is handed over like a hatch")
	task.wait()
	local tool
	for _, t in ipairs(p._backpack:GetChildren()) do
		if t:IsA("Tool") and t:GetAttribute("SpeciesId") == "dustthorn" then
			tool = t
		end
	end
	check(tool ~= nil, "it is a Tool in the Bag")
	if tool then
		tool.Parent = p._body
		local quote, reason = EconomyService.QuoteOne(p, tool)
		check(quote == nil and reason == "UNSELLABLE", "SELL ONE refuses it: UNSELLABLE", reason)
		local held = EconomyService.QuoteHeld(p)
		check(#held.tools == 0 and held.locked == 1, "SELL ALL counts nothing to sell and one invite reward kept",
			held.locked)
		local sold = EconomyService.SellHeld(p)
		check(sold == 0 and tool.Parent == p._body, "SELL ALL sells nothing and the plant stays in the hands")
	end
	check(not SeedData.Sellable(sp) and SeedData.Sellable(SeedData.Get("nubkin")),
		"SeedData.Sellable: no for a reward, yes for an ordinary plant")
	check(PlantInfo.NoSale == "Can't be sold", "the Bag's Sell line for a reward reads \"Can't be sold\"")
	leave(p)
end)

--==============================================================================
section("5. Counting and giving", function()
	local a = enter("Inviter", 42001)
	check(a:GetAttribute(A.Count) == 0 and a:GetAttribute(A.Granted) == 0 and a:GetAttribute(A.Seen) == false,
		"a new inviter: 0 friends, nothing given, the \"!\" up")
	friends(a, 1)
	task.wait()
	check(a:GetAttribute(A.Count) == 1 and a:GetAttribute(A.Granted) == 1 and inviteTools(a).dustthorn == 1
		and heldRows(a, "dustthorn") == 1, "1 friend: Dustthorn given, in the Bag and on the record",
		string.format("count %s granted %s tools %s rows %s", tostring(a:GetAttribute(A.Count)),
			tostring(a:GetAttribute(A.Granted)), tostring(inviteTools(a).dustthorn), tostring(heldRows(a, "dustthorn"))))
	-- A duplicate friend adds nothing.
	check(invite.Credit(a.UserId, nextFriend) == "known" and a:GetAttribute(A.Count) == 1,
		"the same friend again: \"known\", still 1")
	-- The inviter themself never counts.
	joinFor[a] = { ReferredByPlayerId = a.UserId }
	check(invite.CreditJoin(a) == "self" and a:GetAttribute(A.Count) == 1, "a join naming yourself: not counted")
	friends(a, 4)
	task.wait()
	check(a:GetAttribute(A.Count) == 5 and a:GetAttribute(A.Granted) == 2 and inviteTools(a).thornbrute == 1,
		"5 friends: Thornbrute given")
	friends(a, 5)
	task.wait()
	check(a:GetAttribute(A.Granted) == 3 and inviteTools(a).pharaothorn == 1, "10 friends: Pharaothorn given")
	friends(a, 10)
	task.wait()
	check(a:GetAttribute(A.Count) == 20 and a:GetAttribute(A.Granted) == 4 and inviteTools(a).heliothorn == 1,
		"20 friends: Heliothorn given")
	friends(a, 3)
	task.wait()
	local t = inviteTools(a)
	check(t.dustthorn == 1 and t.thornbrute == 1 and t.pharaothorn == 1 and t.heliothorn == 1,
		"23 friends: still exactly one of each")
	check(a:GetAttribute(A.Seen) == false, "a new form puts the \"!\" up")
	check(invite.MarkSeen(a) and a:GetAttribute(A.Seen) == true and not invite.MarkSeen(a),
		"opening the panel takes it down, once")
	-- A rejoin: nothing given twice.
	data.Save(a)
	leave(a)
	local a2 = enter("Inviter", 42001, true)
	-- The saved bag comes back a Tool at a time: wait until all four are in.
	local until_ = os.clock() + 3
	while os.clock() < until_ do
		local n = 0
		for _, c in pairs(inviteTools(a2)) do
			n += c
		end
		if n >= 4 then
			break
		end
		task.wait(0.1)
	end
	invite.GrantOwed(a2)
	task.wait()
	local t2 = inviteTools(a2)
	check(a2:GetAttribute(A.Count) == 23 and a2:GetAttribute(A.Granted) == 4 and t2.dustthorn == 1
		and t2.heliothorn == 1 and heldRows(a2, "heliothorn") == 1, "after a rejoin: the same 23, one of each, nothing new",
		string.format("count %s granted %s tools d%s t%s p%s h%s rows d%d h%d", tostring(a2:GetAttribute(A.Count)),
			tostring(a2:GetAttribute(A.Granted)), tostring(t2.dustthorn), tostring(t2.thornbrute),
			tostring(t2.pharaothorn), tostring(t2.heliothorn), heldRows(a2, "dustthorn"), heldRows(a2, "heliothorn")))
	check(a2:GetAttribute(A.Seen) == true, "the seen flag came back from the save")
	leave(a2)

	-- A friend who has played before is not counted (CountReturningPlayers off).
	local b = enter("Host", 42002)
	store[42003] = ProfileSchema.Sanitise(nil)
	local returning = enter("Returner", 42003)
	joinFor[returning] = { ReferredByPlayerId = b.UserId }
	check(invite.CreditJoin(returning) == "returning" and b:GetAttribute(A.Count) == 0,
		"a returning player joining from an invite: not counted")
	-- A first-time friend is.
	local fresh = enter("Newcomer", 42004)
	joinFor[fresh] = { ReferredByPlayerId = b.UserId }
	check(invite.CreditJoin(fresh) == "here" and b:GetAttribute(A.Count) == 1 and b:GetAttribute(A.Granted) == 1,
		"a first-time player joining from an invite: counted, Dustthorn given")
	leave(returning)
	leave(fresh)
	leave(b)

	-- An inviter in another server, or offline: the inbox, then their next join.
	check(invite.Credit(42005, 777001) == "inbox" and invite.Credit(42005, 777002) == "inbox"
		and invite.Credit(42005, 777001) == "inbox" and #inbox[42005].Ids == 2,
		"an inviter not here: the credit waits in their inbox, each friend once")
	local c = enter("Away", 42005)
	invite.TakeInbox(c)
	invite.GrantOwed(c)
	task.wait()
	check(c:GetAttribute(A.Count) == 2 and c:GetAttribute(A.Granted) == 1 and inviteTools(c).dustthorn == 1
		and #inbox[42005].Ids == 0, "on their join: 2 friends taken from the inbox, Dustthorn given, the inbox empty")
	check(invite.TakeInbox(c) == 0 and c:GetAttribute(A.Count) == 2, "the empty inbox gives nothing more")
	leave(c)

	-- A full Bag: the form waits, then lands.
	local d = enter("Full", 42006)
	local filler = SeedData.Get("nubkin")
	local filled = 0
	while select(1, carry.HeldRoom(d)) > 0 and filled < 40 do
		carry.GiveHatched(d, filler, 1, -1, nil, true)
		filled += 1
	end
	task.wait()
	friends(d, 1)
	task.wait()
	check(d:GetAttribute(A.Count) == 1 and d:GetAttribute(A.Granted) == 0 and (inviteTools(d).dustthorn or 0) == 0,
		"a full Bag: the friend counts, the form waits", d:GetAttribute(A.Granted))
	local gone = {}
	for _, tool in ipairs(d._backpack:GetChildren()) do
		if tool:GetAttribute("SpeciesId") == "nubkin" then
			table.insert(gone, tool)
			tool:Destroy()
			break
		end
	end
	carry.SyncHeldNow(d, gone)
	task.wait()
	invite.GrantOwed(d)
	task.wait()
	check(d:GetAttribute(A.Granted) == 1 and inviteTools(d).dustthorn == 1, "room made: Dustthorn lands")
	leave(d)

	-- The test path judges like a real join.
	check(invite.SimulateJoin(1, 1, true) == "self" and invite.SimulateJoin(5, 6, false) == "returning",
		"the Studio test path judges like a join (self, returning)")
end)

--==============================================================================
section("5b. Told once the client listens", function()
	-- What the server says waits for the client's READY (InviteNews), then
	-- arrives in order; after it, straight away.
	local said = {}
	local realSend = invite.Hooks.send
	invite.Hooks.send = function(p, payload)
		table.insert(said, p.Name .. ":" .. tostring(payload.kind))
	end
	local host = enter("Teller", 42010)
	local guest = enter("Guest", 42011)
	joinFor[guest] = { ReferredByPlayerId = host.UserId }
	check(invite.CreditJoin(guest) == "here" and #said == 0,
		"a counted join before either client listens: nothing sent yet", table.concat(said, " "))
	invite.Ready(host)
	check(table.concat(said, " ") == "Teller:joined Teller:granted",
		"the inviter says READY: +1 INVITE, then the form given, in order", table.concat(said, " "))
	invite.Ready(guest)
	check(said[3] == "Guest:welcome" and #said == 3, "the friend says READY: their WELCOME!, once",
		table.concat(said, " "))
	friends(host, 1)
	check(said[4] == "Teller:joined" and #said == 4, "once listening, the next +1 goes straight out",
		table.concat(said, " "))
	invite.Hooks.send = realSend
	leave(guest)
	leave(host)
end)

--==============================================================================
section("5c. The notices (the owner's notices brief)", function()
	local WORDS = CONFIG.Words
	local said = {}
	local realSend = invite.Hooks.send
	invite.Hooks.send = function(p, payload)
		table.insert(said, { to = p.Name, payload = payload })
	end
	local function last(kind, to)
		for i = #said, 1, -1 do
			local e = said[i]
			if e.payload.kind == kind and (to == nil or e.to == to) then
				return e.payload
			end
		end
		return nil
	end
	local function count(kind, to)
		local n = 0
		for _, e in ipairs(said) do
			if e.payload.kind == kind and (to == nil or e.to == to) then
				n += 1
			end
		end
		return n
	end

	local host = enter("Hostess", 43001)
	invite.Ready(host)
	-- A friend joins this server through the invite and counts.
	local fern = enter("Fern", 43002)
	invite.Ready(fern)
	joinFor[fern] = { ReferredByPlayerId = host.UserId }
	check(invite.CreditJoin(fern) == "here", "a first-time friend joins through the invite: counted")
	local j = last("joined", "Hostess")
	local jw = j and InviteRewards.notice(j)
	check(j ~= nil and j.name == "Fern" and j.count == 1 and jw.kind == "success" and jw.title == "+1 INVITE"
			and jw.detail == "Fern joined! 1/5",
		"the inviter: success +1 INVITE, \"Fern joined! 1/5\" (DisplayName, count / next threshold)", jw and jw.detail)
	-- The friend, on a referral the server read: WELCOME! by the inviter's name.
	local wel = last("welcome", "Fern")
	local ww = wel and InviteRewards.notice(wel)
	check(wel ~= nil and ww.kind == "info" and ww.title == "WELCOME!" and ww.detail == "You joined from Hostess's invite",
		"the friend: info WELCOME!, \"You joined from Hostess's invite\"", ww and ww.detail)
	-- The same friend again: joined, and why it does not count.
	check(invite.Credit(host.UserId, fern.UserId, "Fern") == "known", "the same friend again: \"known\"")
	local k = last("notcounted", "Hostess")
	local kw = k and InviteRewards.notice(k)
	check(k ~= nil and k.why == "known" and kw.kind == "info" and kw.title == "Fern joined"
			and kw.detail == WORDS.NotCountedWhy.known,
		"already counted: info \"Fern joined\", " .. WORDS.NotCountedWhy.known, kw and (kw.title .. " / " .. kw.detail))
	-- A friend who has played before: joined, and why it does not count; no WELCOME!.
	store[43003] = ProfileSchema.Sanitise(nil)
	local rowan = enter("Rowan", 43003)
	invite.Ready(rowan)
	joinFor[rowan] = { ReferredByPlayerId = host.UserId }
	local countBefore = #data.Get(host).InviteIds
	check(invite.CreditJoin(rowan) == "returning", "a friend who has played before: not a count")
	-- 2026-10-08 (A RETURNING FRIEND): one free spin for the inviter, once per
	-- friend, never toward the plants.
	local r = last("returning", "Hostess")
	local rw = r and InviteRewards.notice(r)
	check(r ~= nil and r.name == "Rowan" and rw.kind == "success" and rw.title == WORDS.Returning
			and rw.detail == "Rowan came back from your invite" and last("welcome", "Rowan") == nil
			and spinsFor[#spinsFor] == host.UserId and #data.Get(host).InviteIds == countBefore
			and table.find(data.Get(host).InviteReturnIds, 43003) ~= nil,
		"played before: success +1 FREE SPIN, \"Rowan came back from your invite\", one spin, never a count; no WELCOME!",
		rw and rw.detail)
	local spinsNow = #spinsFor
	check(invite.CreditReturning(host.UserId, 43003, "Rowan") == "known" and #spinsFor == spinsNow
			and last("notcounted", "Hostess").why == "returning",
		"the same returning friend again: \"known\", no second spin -- once per friend, ever")
	check(invite.CreditReturning(host.UserId, host.UserId) == "failed" and #spinsFor == spinsNow,
		"never to yourself")
	check(invite.SimulateJoin(43004, host.UserId, false) == "returning" and #spinsFor == spinsNow + 1
			and last("returning", "Hostess") ~= nil and #data.Get(host).InviteIds == countBefore,
		"the Studio test path pays a returning friend the same way")
	-- Elsewhere: the inbox's own Returning list, beside its Ids, taken on the next read.
	inbox[77001] = { Ids = { 77100 } }
	check(invite.CreditReturning(77001, 77200) == "inbox" and inbox[77001].Returning[1] == 77200
			and inbox[77001].Ids[1] == 77100 and invite.CreditReturning(77001, 77200) == "inbox"
			and #inbox[77001].Returning == 1,
		"an inviter in another server: the friend waits in their inbox (Returning), the Ids beside it untouched, once")
	-- NEVER TWICE (2026-10-08): a plant won on the wheel is not given again by a
	-- milestone, which gives the next plant not yet owned instead.
	local winner = enter("Wheelwinner", 43030)
	invite.Ready(winner)
	data.UpdateInvites(winner, function(pr)
		pr.InviteOwned = { CONFIG.Forms[1] }
		return true
	end)
	check(invite.Credit(winner.UserId, 43031, "Ivy") == "here", "a wheel winner's first friend counts")
	local g = last("granted", "Wheelwinner")
	check(g ~= nil and g.form == CONFIG.Forms[2] and data.Get(winner).InviteGranted == 1
			and table.find(data.Get(winner).InviteOwned, CONFIG.Forms[2]) ~= nil and #data.Get(winner).InviteOwned == 2,
		"their 1-friend milestone gives the next plant NOT owned (" .. CONFIG.Forms[2] .. "), never the wheel's "
			.. CONFIG.Forms[1] .. " again", g and g.form)
	-- Friends from other servers: Roblox's DisplayName, else "a friend" -- never a UserId.
	displayNames[880001] = "Faraway Fox"
	check(invite.Credit(host.UserId, 880001) == "here", "a friend from another server counts here")
	local far = last("joined", "Hostess")
	check(far.name == "Faraway Fox" and InviteRewards.notice(far).detail == "Faraway Fox joined! 2/5",
		"named by Roblox: \"Faraway Fox joined! 2/5\"", InviteRewards.notice(far).detail)
	check(invite.Credit(host.UserId, 880002) == "here", "a friend whose name Roblox does not give")
	local anon = last("joined", "Hostess")
	check(anon.name == nil and InviteRewards.notice(anon).detail == "A friend joined! 3/5",
		"no name: \"A friend joined! 3/5\" -- never the id", InviteRewards.notice(anon).detail)
	local bare = true
	for _, e in ipairs(said) do
		local n = e.payload.name
		if n ~= nil and (type(n) ~= "string" or string.find(n, "^%d+$")) then
			bare = false
		end
	end
	check(bare and InviteRewards.who(880002) == WORDS.SomeFriend and InviteRewards.who("880002") == WORDS.SomeFriend
			and InviteRewards.who("") == WORDS.SomeFriend,
		"no notice carries a bare UserId; a number or an empty name reads \"a friend\"")
	check(InviteRewards.nextAt(0) == 1 and InviteRewards.nextAt(4) == 5 and InviteRewards.nextAt(5) == 10
			and InviteRewards.nextAt(19) == 20 and InviteRewards.nextAt(20) == 20 and InviteRewards.nextAt(50) == 20,
		"the \"/N\": the next threshold, the last one once the final form is earned")
	-- Quick repeated joins: one key, so the same notice refreshes; the second is silent.
	local j1 = InviteRewards.notice({ kind = "joined", name = "A", count = 3 })
	local j2 = InviteRewards.notice({ kind = "joined", name = "B", count = 4 })
	local sounds = InviteSounds.newState()
	check(j1.key == j2.key and j1.title == j2.title and j1.quiet and j1.sound == "joined"
			and InviteSounds.allow(sounds, "joined", 10) and not InviteSounds.allow(sounds, "joined", 11),
		"quick repeated joins: the same notice refreshed (one key, one headline), no extra sound")
	-- CAN'T SEND INVITES, the dialog stubbed: never opened from a test.
	local realHooks = { canSend = InviteSend.Hooks.canSend, prompt = InviteSend.Hooks.prompt }
	local realPost, realPlay = Notice.post, InviteSounds.play
	local posted = {}
	Notice.post = function(post)
		table.insert(posted, post)
	end
	InviteSounds.play = function() end
	InviteSend.Hooks.canSend = function()
		return false
	end
	InviteSend.Hooks.prompt = function()
		error("never opened from a test")
	end
	local refused = InviteSend.prompt()
	InviteSend.Hooks.canSend = function()
		error("CanSendGameInviteAsync failed")
	end
	local failed = InviteSend.prompt()
	InviteSend.Hooks.canSend, InviteSend.Hooks.prompt = realHooks.canSend, realHooks.prompt
	Notice.post, InviteSounds.play = realPost, realPlay
	check(refused == false and failed == false and #posted == 2 and posted[1].kind == "blocked"
			and posted[1].title == "CAN'T SEND INVITES" and posted[1].detail == "Invites aren't available on this account"
			and posted[2].title == "CAN'T SEND INVITES",
		"can't send (false, or the check fails): blocked CAN'T SEND INVITES, \"Invites aren't available on this account\"",
		posted[1] and posted[1].detail)
	-- WHILE YOU WERE AWAY: friends credited while the inviter was away, told once on their next join.
	for _, id in ipairs({ 881001, 881002, 881003 }) do
		invite.Credit(43010, id)
	end
	local wanderer = enter("Wanderer", 43010)
	invite.Ready(wanderer)
	local before = #said
	invite.TakeInbox(wanderer, true)
	local a = last("away", "Wanderer")
	local aw = a and InviteRewards.notice(a)
	check(a ~= nil and a.count == 3 and aw.kind == "info" and aw.title == "WHILE YOU WERE AWAY"
			and aw.detail == "3 friends joined from your invites" and count("joined", "Wanderer") == 0,
		"on their next join: info WHILE YOU WERE AWAY, \"3 friends joined from your invites\" -- not three +1s",
		aw and aw.detail)
	check(invite.TakeInbox(wanderer, true) == 0 and count("away", "Wanderer") == 1 and #said == before + 1,
		"told once: the inbox taken, nothing more to say")
	check(InviteRewards.notice({ kind = "away", count = 1 }).detail == "1 friend joined from your invites",
		"one friend: \"1 friend joined from your invites\"")
	-- While they play, a friend joining elsewhere is a +1 INVITE by name.
	inbox[43010] = { Ids = { 881010 } }
	displayNames[881010] = "Brook"
	invite.TakeInbox(wanderer)
	local later = last("joined", "Wanderer")
	check(later ~= nil and later.name == "Brook" and later.count == 4
			and InviteRewards.notice(later).detail == "Brook joined! 4/5",
		"a friend credited while they play: +1 INVITE, \"Brook joined! 4/5\"")
	-- After the offline earnings card, before the reward cards (the card queue's order).
	local pop = (function()
		local found = game:GetService("StarterPlayer"):FindFirstChild("InviteRewardUI", true)
		local ok, src = pcall(function()
			return found.Source
		end)
		return if ok then src else ""
	end)()
	local function has(needle)
		return string.find(pop, needle, 1, true) ~= nil
	end
	check(has("elseif away > 0 then\n\t\t\t\ttellAway()") and has("local due = player:GetAttribute(OFFLINE_CASH)")
			and has("if os.clock() - startedAt < POP.JoinSettle then") and has('payload.kind == "away" then'),
		"WHILE YOU WERE AWAY: after the offline earnings card (and the join's settle), before the reward cards")
	-- A Play on a phone (2026-10-06): a form given a moment after the notice came
	-- up with it. No card sooner than AwayLead after it, however the two arrive.
	check(has("tellAway()\n\t\t\t\tcardsAfter = os.clock() + POP.AwayLead")
			and has("elseif os.clock() < cardsAfter then\n\t\t\t\ttask.wait(POP.Wait)")
			and GameConfig.InviteRewards.Popup.AwayLead > 0,
		"WHILE YOU WERE AWAY: the cards wait AwayLead after it, even a form that arrives a moment later")
	invite.Hooks.send = realSend
	for _, p in ipairs({ fern, rowan, wanderer, host }) do
		leave(p)
	end
end)

--==============================================================================
section("6. The rigs", function()
	local function motorsOf(model)
		local names, n = {}, 0
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Motor6D") then
				names[d.Name] = true
				n += 1
			end
		end
		return names, n
	end
	local posed = {}
	for _, name in ipairs(PlantIdles.InviteJoints) do
		posed[name] = true
	end
	for i, id in ipairs(IDS) do
		local sp = SeedData.Get(id)
		local cf = CFrame.new(0, 900, 4000 + i * 200)
		local model = CreatureModel.BuildCreature(sp, SeedData.InviteTier, CreatureModel.STAGE_GROWN, cf, fixture)
		local motors, count = motorsOf(model)
		local walk = PlantIdles.Walks[id]
		local legsOk = walk ~= nil and #walk.legs == 2
		for _, leg in ipairs(walk and walk.legs or {}) do
			legsOk = legsOk and motors[leg.hip] and motors[leg.knee] and motors[leg.ankle]
		end
		check(legsOk, id .. ": the walk's two legs (hip, knee, ankle) are the rig's own joints")
		local profile = InviteForms.Profiles[id].idle
		check(motors[profile.chest] ~= nil, id .. ": its breath rides on " .. profile.chest .. ", a joint it has")
		local idleNames = {}
		for name in pairs(motors) do
			if posed[name] then
				table.insert(idleNames, name)
			end
		end
		table.sort(idleNames)
		say(string.format("     %s: %d Motor6Ds; the idle poses %d: %s", id, count, #idleNames,
			table.concat(idleNames, " ")))
		-- 600 frames of idle, then compared with a fresh copy at the same moment.
		local rigA = SecretIdle.Rig(model)
		check(rigA ~= nil and rigA.plant ~= nil and rigA.gait ~= nil,
			id .. ": the animator takes it, with an idle and a walk")
		local t = 0
		for _ = 1, 600 do
			t += 1 / 30
			SecretIdle.Step(rigA, 1000 + t)
		end
		local twin = CreatureModel.BuildCreature(sp, SeedData.InviteTier, CreatureModel.STAGE_GROWN, cf, fixture)
		local rigB = SecretIdle.Rig(twin)
		rigB.phase = rigA.phase
		rigB.lastEvent = rigA.lastEvent
		SecretIdle.Step(rigB, 1000 + t)
		local worst = 0
		for k, node in ipairs(rigA.nodes) do
			local other = rigB.nodes[k]
			if other and other.part.Name == node.part.Name then
				worst = math.max(worst, (node.part.Position - other.part.Position).Magnitude)
			end
		end
		check(worst < 1e-3, string.format("%s: after 600 frames it stands exactly as a fresh copy does (worst %.5f studs)",
			id, worst), worst)
		SecretIdle.Rest(rigA)
		local restWorst = 0
		local pivot = model:GetPivot()
		for _, node in ipairs(rigA.nodes) do
			restWorst = math.max(restWorst, (pivot:ToObjectSpace(node.part.CFrame).Position - node.rel.Position).Magnitude)
		end
		check(restWorst < 1e-3, string.format("%s: at rest it is the built pose (worst %.5f)", id, restWorst), restWorst)
		-- The walk: on its rung's speed, the feet's lowest point never through the soil.
		rigA.walks = true
		local speed = SeedData.WanderSpeed(SeedData.WanderTierOf(sp, SeedData.InviteTier))
		local pivot0 = model:GetPivot()
		local lowest = math.huge
		local nan = false
		for f = 1, 300 do
			local dz = speed * f / 30
			model:PivotTo(pivot0 * CFrame.new(0, 0, -dz))
			SecretIdle.Step(rigA, 2000 + f / 30)
			if f > 30 then
				local frame = cf * CFrame.new(0, 0, -dz)
				for _, leg in ipairs(walk.legs) do
					for _, node in ipairs(rigA.nodes) do
						if node.motor == leg.ankle then
							local y = frame:PointToObjectSpace(node.part.Position).Y
							lowest = math.min(lowest, y)
							if y ~= y then
								nan = true
							end
						end
					end
				end
			end
		end
		check(not nan and lowest > -0.25 and lowest < sp.Height * 0.25, string.format(
			"%s: walking at %.2f studs/s on rung %d, the ankles stay on the soil (lowest %.2f)", id, speed,
			SeedData.WanderTierOf(sp, SeedData.InviteTier), lowest), lowest)
		model:Destroy()
		twin:Destroy()
	end
	-- The pedestal's copy: scaled whole, its lights with it, tagged for the idle, never walking.
	local CollectionService = game:GetService("CollectionService")
	for _, id in ipairs(IDS) do
		local scale = InviteRewards.displayScale(id)
		local m = Instance.new("Model")
		SecretModel.BuildDisplay(id, CFrame.new(0, 950, 0), m, scale)
		m.Parent = fixture
		local _, size = m:GetBoundingBox()
		local spec = InviteForms.Plants[id]
		local lightOk = true
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("PointLight") then
				local matched = false
				for _, l in ipairs(spec.Lights) do
					if l.n == d.Name and math.abs(d.Range - l.range * scale) < 1e-3 then
						matched = true
					end
				end
				lightOk = lightOk and matched
			end
		end
		check(m:GetAttribute(SecretModel.SCALE_ATTRIBUTE) == scale and lightOk and m.PrimaryPart ~= nil
			and CollectionService:HasTag(m, SecretModel.RIG_TAG)
			and not CollectionService:HasTag(m, GameConfig.Tags.Planted),
			string.format("%s on the pedestal: x%.3f, %.1f studs tall, lights scaled, idle only", id, scale, size.Y))
		m:Destroy()
	end
	-- The copy fills the room under the sign (the owner, 2026-10-06: "the plant
	-- must not look small"), its aura's flare never at the keyline or a pillar.
	local room = InviteRewards.displayRoom()
	for _, id in ipairs(IDS) do
		local scale = InviteRewards.displayScale(id)
		local restTop, restHalf = InviteRewards.formReach(id, 1)
		local flareTop, flareHalf = InviteRewards.formReach(id, CONFIG.AuraSwell)
		local m = Instance.new("Model")
		SecretModel.BuildDisplay(id, CFrame.new(0, 950, 0), m, scale)
		m.Parent = fixture
		local box, size = m:GetBoundingBox()
		local top = box.Position.Y + size.Y / 2 - 950
		m:Destroy()
		check(top >= 0.85 * room.height and restTop * scale <= CONFIG.DisplayFill * room.height + 1e-6
				and flareTop * scale <= room.height - CONFIG.DisplayClear + 1e-6
				and flareHalf * scale <= room.half - CONFIG.DisplayClear + 1e-6 and math.abs(top - restTop * scale) < 0.05,
			string.format("%s fills the room under the sign: x%.3f, %.2f of %.2f studs (%.0f%%), %.2f wide; at a flare's "
				.. "top %.2f high, %.2f to a side of %.2f", id, scale, top, room.height, 100 * top / room.height,
				2 * restHalf * scale, flareTop * scale, flareHalf * scale, room.half))
	end
	local hub = (function()
		local found = game:GetService("StarterPlayer"):FindFirstChild("InviteHub", true)
		local ok, src = pcall(function()
			return found.Source
		end)
		return if ok then src else ""
	end)()
	check(string.find(hub, "d.Range = math.min(d.Range, CONFIG.DisplayLightMax)", 1, true) ~= nil
			and CONFIG.DisplayLightMax == 60,
		"the pedestal copy's lights scale with it, never past 60 studs (InviteHub; a granted plant's are its own)")
end)

end)

fixture:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("InviteRewardsSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
