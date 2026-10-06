--!nocheck
--==============================================================================
-- Steal a Seed :: AdminSpec
--
-- The two-account admin console, on the server: who may ask, what may be
-- asked, and what each action does to a profile. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("AdminSpec"))
--
-- The REAL AdminService, PlayerDataService, EconomyService and TreadmillService,
-- fresh-required, with stand-in players joined the way AlmanacClaimSpec joins
-- them: SaveService's Load and Save are stubbed -- so no DataStore is read or
-- written, and no real profile is touched -- and the calls a progress reset
-- makes into the world (the garden, the plot, the mill, the bag, the trap, the
-- respawn) are recorded rather than performed, so their ORDER can be checked.
-- The allowlisted UserIds appear here only on stand-in tables.
--
-- Not here: the round trip over the RemoteFunction, the panel, and a real
-- respawn rebuilding a real bag (Play, on a throwaway store). Start Night and
-- Start Day reach stand-ins for WorldCycleService's two doors here -- this is
-- about who may press them and what they are told; CycleSpec runs the real
-- transitions.
--==============================================================================
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local Server = game:GetService("ServerScriptService").SeedGameServer
local SaveService = require(Server.SaveService)
local PlotService = require(Server.PlotService)
local ProfileSchema = require(Server.ProfileSchema)
local PlayerDataService = require(Server.PlayerDataService)
local EconomyService = require(Server.EconomyService)
local TreadmillService = require(Server.TreadmillService)
local PlantService = require(Server.PlantService)
local CarryService = require(Server.CarryService)
local CombatService = require(Server.CombatService)
local WeaponShopService = require(Server.WeaponShopService)
local WorldCycleService = require(Server.WorldCycleService)
local AdminService = require(Server.AdminService)

local SAVE = GameConfig.Save
local ADMIN_A, ADMIN_B = 4119740186, 11607308004

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
fixture.Name = "AdminSpecFixture"
fixture.Archivable = false
fixture.Parent = ServerStorage

--==============================================================================
-- THE STUBS, AND WHAT THEY RECORD
--==============================================================================
local saves: any, plots: any, data: any = SaveService, PlotService, PlayerDataService
local treads: any, plants: any, carry: any = TreadmillService, PlantService, CarryService
local combat: any, shop: any, admin: any = CombatService, WeaponShopService, AdminService
local cycle: any = WorldCycleService
local real = {
	StartNight = cycle.StartNight, StartDay = cycle.StartDay,
	Load = saves.Load, Save = saves.Save, Forget = saves.Forget,
	SetDesiredLevel = plots.SetDesiredLevel, PlotOf = plots.PlotOf,
	MountStats = data.MountStats,
	Unmount = treads.Unmount, Rebuild = treads.Rebuild,
	ClearGarden = plants.ClearGarden,
	ForfeitCarry = carry.ForfeitCarry, SyncHeldNow = carry.SyncHeldNow,
	RefreshWalkSpeed = carry.RefreshWalkSpeed,
	ClearTrap = combat.ClearTrap, RefreshTools = shop.RefreshTools,
	FindPlayer = admin.FindPlayer, MinInterval = admin.Config.MinInterval,
}

local calls: { { name: string, args: { any } } } = {}
local function note(name, ...)
	table.insert(calls, { name = name, args = { ... } })
end
local function indexOf(name, from)
	for i = from or 1, #calls do
		if calls[i].name == name then
			return i
		end
	end
	return nil
end

local answer = { status = "ok", raw = nil }
local saveOk = true
local slowSave = false
local savedPayloads = {}
saves.Load = function()
	return answer.status, answer.raw
end
saves.Save = function(userId, payload)
	note("Save", userId)
	if slowSave then
		task.wait(0.3)
	end
	table.insert(savedPayloads, { userId = userId, cash = payload.Cash, speed = payload.Speed,
		plants = #(payload.Plants or {}), held = #(payload.Held or {}), receipts = table.clone(payload.Receipts or {}) })
	return saveOk
end
saves.Forget = function() end

local plotFor = {}
plots.PlotOf = function(player)
	return plotFor[player]
end
plots.SetDesiredLevel = function(player, level)
	note("SetDesiredLevel", player, level)
	return true
end
local holders = {}
data.MountStats = function(holder, profile)
	return real.MountStats(holders[holder] or holder, profile)
end
treads.Unmount = function(player)
	note("Unmount", player)
end
treads.Rebuild = function(plot, tier)
	note("Rebuild", plot, tier)
end
plants.ClearGarden = function(player, plot)
	local profile = data.Get(player)
	note("ClearGarden", player, plot, profile and profile.Cash)
	return 2
end
carry.ForfeitCarry = function(player, why)
	note("ForfeitCarry", player, why)
	return nil, 0
end
carry.SyncHeldNow = function(player, consumed)
	local profile = data.Get(player)
	note("SyncHeldNow", player, consumed and #consumed or 0, profile and profile.Cash)
end
carry.RefreshWalkSpeed = function(player)
	note("RefreshWalkSpeed", player)
end
combat.ClearTrap = function(player)
	note("ClearTrap", player)
end
shop.RefreshTools = function(player)
	note("RefreshTools", player)
end

-- WorldCycleService's two doors, answering the way the real ones do: the phase
-- already running is ALREADY_*, and `world.force` makes one say BUSY or FAILED.
local world = { phase = "Day", force = nil }
cycle.StartNight = function()
	note("StartNight")
	if world.force then
		return false, world.force
	end
	if world.phase == "Night" then
		return false, "ALREADY_NIGHT"
	end
	world.phase = "Night"
	return true, "OK"
end
cycle.StartDay = function()
	note("StartDay")
	if world.force then
		return false, world.force, nil, nil
	end
	if world.phase == "Day" then
		return false, "ALREADY_DAY", nil, nil
	end
	world.phase = "Day"
	return true, "OK", 5, 5
end
local function callsOf(name, from)
	local n = 0
	for i = from + 1, #calls do
		if calls[i].name == name then
			n += 1
		end
	end
	return n
end

--==============================================================================
-- STAND-IN PLAYERS
--==============================================================================
local byId = {}
admin.FindPlayer = function(userId)
	local p = byId[userId]
	if p and p.Parent ~= nil then
		return p
	end
	return nil
end

local function stand(name, userId, parent)
	local holder = Instance.new("Folder")
	holder.Name = name
	holder.Parent = fixture
	local characterAdded = Instance.new("BindableEvent")
	characterAdded.Parent = holder
	local backpack = Instance.new("Backpack")
	backpack.Parent = holder
	local character = Instance.new("Model")
	character.Name = name .. "Body"
	character.Parent = holder
	local attrs = {}
	local p = {
		Name = name,
		UserId = userId,
		Parent = parent,
		Character = character,
		CharacterAdded = characterAdded.Event,
		_backpack = backpack,
		_holder = holder,
	}
	function p.SetAttribute(_, k, v)
		attrs[k] = v
	end
	function p.GetAttribute(_, k)
		return attrs[k]
	end
	function p.Kick() end
	function p.FindFirstChildOfClass(_, className)
		if className == "Backpack" and backpack.Parent then
			return backpack
		end
		return nil
	end
	function p.LoadCharacter(self)
		note("LoadCharacter", self)
	end
	function p.WaitForChild(_, childName)
		return holder:FindFirstChild(childName)
	end
	holders[p] = holder
	byId[userId] = p
	return p
end

local joined = {}
local function join(name, userId, shape, status)
	local raw = ProfileSchema.Sanitise(nil)
	for k, v in pairs(shape or {}) do
		raw[k] = v
	end
	answer.status, answer.raw = status or "ok", raw
	local p = stand(name, userId, Players)
	data.Join(p)
	table.insert(joined, p)
	return p, data.Get(p)
end

local function tool(parent, name, attrs)
	local t = Instance.new("Tool")
	t.Name = name
	t.RequiresHandle = false
	for k, v in pairs(attrs or {}) do
		t:SetAttribute(k, v)
	end
	t.Parent = parent
	return t
end

local function toolsIn(p)
	local n = 0
	for _, c in ipairs({ p._backpack, p.Character }) do
		for _, x in ipairs(c:GetChildren()) do
			if x:IsA("Tool") then
				n += 1
			end
		end
	end
	return n
end

local ok, err = pcall(function()
	admin.Config.MinInterval = 0
	local adminA = join("AdminA", ADMIN_A, { Cash = 0, Speed = 0 })
	local adminB = join("AdminB", ADMIN_B, { Cash = 0, Speed = 0 })
	local target, profile = join("SpecTarget", 5551, { Cash = 1000, Speed = 2000 })

	--==========================================================================
	-- 1. WHO MAY ASK: TWO NUMERIC USER IDS
	--==========================================================================
	say("-- the allowlist --")
	check(admin.IsAdmin(adminA) and admin.IsAdmin(adminB), "both verified UserIds are admins")
	local strangers = {
		{ UserId = 1, Name = "nicnicniccoal" },
		{ UserId = 5551, Name = "Teambarnze825", DisplayName = "nicnicniccoal" },
		{ UserId = 0 }, { UserId = -ADMIN_A }, { UserId = ADMIN_A + 0.5 },
		{ UserId = tostring(ADMIN_A) }, { Name = "nicnicniccoal" }, {}, "nicnicniccoal", ADMIN_A, nil,
	}
	local anyAdmin = false
	for _, s in ipairs(strangers) do
		if admin.IsAdmin(s) then
			anyAdmin = true
		end
	end
	check(not anyAdmin,
		"nobody else: not by username, display name, a string id, a negated or fractional id, or a bare number")
	local src = sourceOf(Server.AdminService) or ""
	local list = string.match(src, "local ALLOWED[^\n]*=%s*{(.-)}")
	local ids = {}
	for id in string.gmatch(list or "", "%[(%d+)%]") do
		table.insert(ids, tonumber(id))
	end
	table.sort(ids)
	check(#ids == 2 and ids[1] == ADMIN_A and ids[2] == ADMIN_B,
		"the allowlist in the source is exactly 4119740186 and 11607308004", table.concat(ids, ","))
	local isAdminBody = string.match(src, "function AdminService%.IsAdmin(.-)\nend") or ""
	check(isAdminBody ~= "" and not string.find(isAdminBody, "Name", 1, true)
			and not string.find(isAdminBody, "Attribute", 1, true)
			and not string.find(isAdminBody, "Rank", 1, true),
		"IsAdmin reads the UserId and nothing else")
	check((GameConfig :: any).Admin == nil and (GameConfig :: any).Debug == nil
			and (GameConfig.Remotes :: any).AdminRequest == nil,
		"nothing about admins is in GameConfig, which every client can read")

	--==========================================================================
	-- 2. A FORGED REQUEST FROM ANYBODY ELSE CHANGES NOTHING
	--==========================================================================
	say("\n-- forged requests --")
	local before = #calls
	local refusedAll = true
	for _, s in ipairs({ target, { UserId = 1 }, { UserId = 5551, Name = "nicnicniccoal" }, nil, "x" }) do
		for _, action in ipairs({ "AddMoney", "AddSpeed", "ResetPlayerProgress", "StartNight", "StartDay" }) do
			local reply = admin.Handle(s, action, ADMIN_A, 1000, "nicnicniccoal")
			if reply.ok or reply.message ~= "Not authorized." then
				refusedAll = false
			end
		end
	end
	check(refusedAll, "every action from a non-admin -- even aimed at an admin -- is \"Not authorized.\"")
	check(#calls == before and profile.Cash == 1000 and profile.Speed == 2000 and world.phase == "Day",
		"and nothing was called and nothing moved -- not a profile, not the night")

	--==========================================================================
	-- 3. ADD MONEY, ADD SPEED
	--==========================================================================
	say("\n-- grants --")
	local reply = admin.Handle(adminA, "AddMoney", target.UserId, 5000)
	check(reply.ok and reply.added == 5000 and profile.Cash == 6000,
		"AddMoney pays through the faucet: 1,000 + 5,000", reply.message)
	check(string.find(reply.message, "$5,000", 1, true) ~= nil, "and says how much, exactly", reply.message)
	local stats = holders[target]:FindFirstChild("leaderstats")
	check(stats and stats.Cash.Value == "$" .. GameConfig.money(6000),
		"the player-list column moved with it", stats and stats.Cash.Value)
	reply = admin.Handle(adminB, "AddSpeed", target.UserId, 3000)
	check(reply.ok and reply.added == 3000 and profile.Speed == 5000,
		"AddSpeed pays through the mill's faucet: 2,000 + 3,000", reply.message)
	local trail = admin.Audit()
	local last = trail[#trail]
	check(last and last.action == "AddSpeed" and last.admin == ADMIN_B and last.target == 5551
			and last.amount == 3000 and type(last.at) == "string"
			and string.match(last.at, "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d") ~= nil,
		"each success is recorded: admin, target, action, amount and an ISO time", last and last.at)

	-- The cap: the grant is cut short and says so.
	profile.Cash = SAVE.MaxCash - 50
	reply = admin.Handle(adminA, "AddMoney", target.UserId, 1000)
	check(reply.ok and reply.added == 50 and profile.Cash == SAVE.MaxCash
			and string.find(reply.message, "limit", 1, true) ~= nil,
		"at the cap, 50 of 1,000 lands, and the message says the limit stopped the rest", reply.message)
	trail = admin.Audit()
	check(trail[#trail].amount == 50 and trail[#trail].asked == 1000,
		"and the record keeps both: 50 added, 1,000 asked")
	reply = admin.Handle(adminA, "AddMoney", target.UserId, 1000)
	check(not reply.ok and string.find(reply.message, "already at", 1, true) ~= nil,
		"already at the cap: refused, nothing to add", reply.message)
	profile.Cash = 6000

	--==========================================================================
	-- 4. AMOUNTS
	--==========================================================================
	say("\n-- amounts --")
	local bad = { 0, -5, 1.5, 0 / 0, math.huge, -math.huge, "1000", true, {}, nil,
		admin.Config.MaxMoney + 1, 2 ^ 53 }
	local allRefused = true
	for _, value in ipairs(bad) do
		local r1 = admin.Handle(adminA, "AddMoney", target.UserId, value)
		local r2 = admin.Handle(adminA, "AddSpeed", target.UserId, value)
		if r1.ok or r2.ok then
			allRefused = false
		end
	end
	check(allRefused and profile.Cash == 6000 and profile.Speed == 5000,
		"zero, negative, fractional, NaN, both infinities, strings, nil and over-limit are all refused, and nothing moved")
	reply = admin.Handle(adminA, "AddMoney", target.UserId, admin.Config.MaxMoney)
	check(reply.ok and reply.added == admin.Config.MaxMoney, "the limit itself is allowed", reply.message)
	profile.Cash = 6000

	--==========================================================================
	-- 5. ACTIONS AND TARGETS
	--==========================================================================
	say("\n-- actions and targets --")
	local unknown = true
	for _, action in ipairs({ "ResetCharacter", "SetCash", "Kick", "", 42, nil, {} }) do
		if admin.Handle(adminA, action, target.UserId, 1000, target.Name).ok then
			unknown = false
		end
	end
	check(unknown, "anything but the five actions is refused -- including the old ResetCharacter")
	reply = admin.Handle(adminA, "AddMoney", 999999, 1000)
	check(not reply.ok and string.find(reply.message, "no longer", 1, true) ~= nil,
		"a UserId nobody in this server has: refused", reply.message)
	local badIds = true
	for _, id in ipairs({ "5551", 5551.5, -5551, 0, 0 / 0, nil, {} }) do
		if admin.Handle(adminA, "AddMoney", id, 1000).ok then
			badIds = false
		end
	end
	check(badIds, "a target that is not a positive whole UserId is refused")
	local leaver = join("SpecLeaver", 5552, {})
	leaver.Parent = nil
	reply = admin.Handle(adminA, "AddMoney", 5552, 1000)
	check(not reply.ok and string.find(reply.message, "no longer", 1, true) ~= nil,
		"a target who has left the server: refused", reply.message)
	local loading = stand("SpecLoading", 5553, Players)
	reply = admin.Handle(adminA, "AddMoney", 5553, 1000)
	check(not reply.ok and string.find(reply.message, "not loaded", 1, true) ~= nil,
		"a target whose profile has not loaded: refused cleanly", reply.message)
	check(profile.Cash == 6000 and data.Get(loading) == nil, "and none of those changed anything")

	--==========================================================================
	-- 6. REPEATED REQUESTS
	--==========================================================================
	say("\n-- rate limit --")
	admin.Config.MinInterval = 1
	task.wait(1.05)
	local first = admin.Handle(adminA, "AddMoney", target.UserId, 10)
	local second = admin.Handle(adminA, "AddMoney", target.UserId, 10)
	check(first.ok and not second.ok and string.find(second.message, "Too fast", 1, true) ~= nil,
		"a second request inside a second is refused", second.message)
	check(profile.Cash == 6010, "and only the first paid", profile.Cash)
	local other = admin.Handle(adminB, "AddMoney", target.UserId, 10)
	check(other.ok, "the limit is per admin: the other admin is not held up", other.message)
	task.wait(1.05)
	check(admin.Handle(adminA, "AddMoney", target.UserId, 10).ok, "a second later it works again")
	admin.Config.MinInterval = 0
	profile.Cash = 6000

	--==========================================================================
	-- 7. RESET PLAYER PROGRESS
	--==========================================================================
	say("\n-- reset: the confirmation --")
	local rich, richProfile = join("SpecRich", 5560, {
		Cash = 5e6, Speed = 7e6, PlotTier = 3, MillTier = 4, MillOverclock = 2,
		HighestBiomeOrder = 3, Almanac = { nubkin = true }, Mastery = { greenhollow = true },
		Weapons = { rootwood_bat = true }, EquippedBat = "rootwood_bat",
		Plants = { { SpeciesId = "nubkin", Tier = 1, X = 0, Z = 0, PlantedAt = 1, Stage = 1, Facing = 0 } },
		Held = { { Id = "nubkin", Tier = 2, Hatched = false, Item = "8" } }, NextItem = 9,
		Receipts = { "receipt-1", "receipt-2" }, WalkMode = true, MenuSize = "large", CreatedAt = 1700000000,
		OfflineCash = 1234, OfflineSeconds = 60, OfflineAway = 120,
		-- The hotbar and the hearts (2026-10-03): progress, so not kept.
		Hotbar = { "w:rootwood_bat", "", "", "i:8", "", "", "", "", "", "" },
		Favourites = { ["i:8"] = true, ["w:rootwood_bat"] = true },
	})
	local plot = Instance.new("Model")
	plot.Name = "SpecRichPlot"
	plot.Parent = fixture
	plotFor[rich] = plot
	tool(rich._backpack, "Pod", { SpeciesId = "nubkin", CarryingKg = 2 })
	tool(rich._backpack, "Bat", { WeaponItem = "rootwood_bat" })
	tool(rich.Character, "Held", { SpeciesId = "nubkin", CarryingKg = 1, Hatched = true })
	local tutorialBefore = richProfile.Tutorial
	check(richProfile.Cash == 5e6 and richProfile.Receipts[2] == "receipt-2" and toolsIn(rich) == 3,
		"(the fixture: a rich profile, two receipts, three Tools out)")

	local callsBefore = #calls
	local wrong = true
	for _, typed in ipairs({ nil, "", "   ", "SpecRic", "SpecRich2", "someone", 42, string.rep("x", 70) }) do
		if admin.Handle(adminA, "ResetPlayerProgress", rich.UserId, nil, typed).ok then
			wrong = false
		end
	end
	check(wrong, "without the username typed back exactly, a reset is refused")
	check(#calls == callsBefore and richProfile.Cash == 5e6 and toolsIn(rich) == 3,
		"and nothing was touched: no world call, no Tool, no profile field")

	local temp = join("SpecTemp", 5561, { Cash = 99 }, "unavailable")
	-- Marked after the join: joining a stand-in calls the stubbed SetDesiredLevel.
	local tempMark = #calls
	reply = admin.Handle(adminA, "ResetPlayerProgress", temp.UserId, nil, "SpecTemp")
	check(not reply.ok and string.find(reply.message, "not saving", 1, true) ~= nil
			and data.Get(temp).Cash == 99 and #calls == tempMark,
		"a TEMPORARY profile cannot be reset for real: refused before anything moves", reply.message)

	say("\n-- reset: done, and saved --")
	local sameTable = data.Get(rich)
	-- The window the order is read from starts HERE, after every join above.
	callsBefore = #calls
	reply = admin.Handle(adminB, "ResetPlayerProgress", rich.UserId, nil, "  specrich ")
	check(reply.ok and string.find(reply.message, "saved", 1, true) ~= nil,
		"typed back (any case, spaces trimmed), the reset runs and reports SAVED", reply.message)

	local fresh = ProfileSchema.Default()
	local p = data.Get(rich)
	check(p == sameTable, "the profile was reset IN PLACE: every holder of it sees the reset")
	check(p.Cash == 0 and p.Speed == 0 and p.PlotTier == fresh.PlotTier and p.MillTier == fresh.MillTier
			and p.MillOverclock == 0 and p.HighestBiomeOrder == 1,
		"cash, Speed, plot and mill tiers, overclock and the biome mark are the schema's defaults")
	check(#p.Plants == 0 and #p.Held == 0 and next(p.Almanac) == nil and next(p.Mastery) == nil
			and next(p.Weapons) == nil and p.EquippedBat == "" and p.EquippedTrap == "",
		"plants, the bag, the Almanac, harvests and bought weapons are empty")
	check(p.OfflineCash == 0 and p.OfflineSeconds == 0 and p.OfflineAway == 0,
		"and the offline claim is gone")
	check(p.Tutorial ~= tutorialBefore and type(p.Tutorial) == "table"
			and p.TrainingCharge == nil and p.TrainingChargeAt == nil,
		"tutorial progress starts over (and a reset profile carries no training charge: the Rush is gone, 2026-10-05)")
	check(#p.Receipts == 2 and p.Receipts[1] == "receipt-1" and p.Receipts[2] == "receipt-2",
		"the Robux receipts are KEPT, so nothing already bought can be granted twice")
	check(p.CreatedAt == 1700000000 and p.WalkMode == true and p.Version == SAVE.CurrentVersion,
		"and so are when the account was made and the Walk Mode setting")
	check(p.MenuSize == "large", "and the chosen menu size, a setting like Walk Mode", p.MenuSize)
	check(table.concat(p.Hotbar, ",") == table.concat(fresh.Hotbar, ",") and next(p.Favourites) == nil,
		"the hotbar is a new player's three faint slots again, and no item wears a heart",
		table.concat(p.Hotbar, ","))
	check(p.NextItem == 9, "but NextItem is KEPT: no item id is ever handed out twice", p.NextItem)
	local shape = true
	for key in pairs(fresh) do
		if p[key] == nil then
			shape = false
		end
	end
	for key in pairs(p) do
		if fresh[key] == nil then
			shape = false
		end
	end
	check(shape, "the reset profile has exactly the schema's fields, no more and no fewer")
	check(toolsIn(rich) == 0, "every Tool in the bag and the hands is gone")
	local richStats = holders[rich]:FindFirstChild("leaderstats")
	check(richStats and richStats.Cash.Value == "$0" and richStats.Speed.Value == "0",
		"the player-list columns read the fresh zeros", richStats and richStats.Cash.Value)

	local order = { "Unmount", "ForfeitCarry", "ClearTrap", "ClearGarden", "SyncHeldNow",
		"SetDesiredLevel", "Rebuild", "RefreshTools", "RefreshWalkSpeed", "Save", "LoadCharacter" }
	local at, ordered, missing = callsBefore, true, {}
	for _, name in ipairs(order) do
		local i = indexOf(name, callsBefore + 1)
		if not i then
			table.insert(missing, name)
		elseif i < at then
			ordered = false
		else
			at = i
		end
	end
	check(#missing == 0 and ordered,
		"in order: off the mill, carry forfeited, trap lifted, garden cleared, bag recorded, plot, mill, "
			.. "weapons, WalkSpeed, SAVE, then the new body", table.concat(missing, ","))
	local garden = calls[indexOf("ClearGarden", callsBefore + 1) or 1]
	local synced = calls[indexOf("SyncHeldNow", callsBefore + 1) or 1]
	check(garden and garden.args[2] == plot and garden.args[3] == 5e6,
		"the garden was cleared BEFORE the record was reset -- nothing left to persist back")
	check(synced and synced.args[2] == 3 and synced.args[3] == 0,
		"and the three destroyed Tools were handed to the hotbar record AFTER it was reset")
	local plotCall = calls[indexOf("SetDesiredLevel", callsBefore + 1) or 1]
	local millCall = calls[indexOf("Rebuild", callsBefore + 1) or 1]
	check(plotCall and plotCall.args[2] == fresh.PlotTier and millCall and millCall.args[1] == plot
			and millCall.args[2] == fresh.MillTier,
		"the plot rebuilt at the starting level and the mill at the starting tier")
	local forfeit = calls[indexOf("ForfeitCarry", callsBefore + 1) or 1]
	check(forfeit and forfeit.args[2] == "an admin progress reset",
		"a carried pod is forfeited under its real reason, not nightfall's")
	local saved = savedPayloads[#savedPayloads]
	check(saved and saved.userId == 5560 and saved.cash == 0 and saved.speed == 0 and saved.plants == 0
			and saved.held == 0 and #saved.receipts == 2,
		"what was SAVED is the fresh profile, receipts and all")
	trail = admin.Audit()
	check(trail[#trail].action == "ResetPlayerProgress" and trail[#trail].admin == ADMIN_B
			and trail[#trail].target == 5560,
		"and the reset is on the record")

	say("\n-- reset: not saved is not a success --")
	local unlucky = join("SpecUnlucky", 5562, { Cash = 777 })
	saveOk = false
	local mark = #calls
	reply = admin.Handle(adminA, "ResetPlayerProgress", unlucky.UserId, nil, "SpecUnlucky")
	saveOk = true
	check(not reply.ok and string.find(reply.message, "SAVE DID NOT LAND", 1, true) ~= nil,
		"a save that fails is reported as a failure, never as done", reply.message)
	check(data.Get(unlucky).Cash == 0 and indexOf("LoadCharacter", mark + 1) ~= nil,
		"the reset still stands in memory (the autosave keeps trying) and the body is rebuilt")
	trail = admin.Audit()
	check(trail[#trail].target ~= 5562, "and a failed save is not recorded as a success")

	say("\n-- reset: mid-respawn, no Backpack --")
	local bare = join("SpecBare", 5564, { Cash = 3 })
	tool(bare.Character, "InHand", { SpeciesId = "nubkin", CarryingKg = 1 })
	bare._backpack.Parent = nil
	reply = admin.Handle(adminA, "ResetPlayerProgress", bare.UserId, nil, "SpecBare")
	check(reply.ok and #bare.Character:GetChildren() == 0,
		"with no Backpack at that moment, the Tool in the hands still goes", reply.message)

	say("\n-- reset: one at a time --")
	local twice = join("SpecTwice", 5563, { Cash = 5 })
	slowSave = true
	local firstReply = nil
	task.spawn(function()
		firstReply = admin.Handle(adminA, "ResetPlayerProgress", twice.UserId, nil, "SpecTwice")
	end)
	local overlap = admin.Handle(adminB, "ResetPlayerProgress", twice.UserId, nil, "SpecTwice")
	task.wait(0.5)
	slowSave = false
	check(not overlap.ok and string.find(overlap.message, "already running", 1, true) ~= nil,
		"a second reset of the same player while the first is saving is refused", overlap.message)
	check(firstReply and firstReply.ok, "and the first one finishes", firstReply and firstReply.message)

	--==========================================================================
	-- 8. START NIGHT, START DAY: THE WHOLE SERVER
	--==========================================================================
	say("\n-- day and night --")
	local worldMark = #calls
	reply = admin.Handle(adminA, "StartNight")
	check(reply.ok and world.phase == "Night"
			and string.find(reply.message, "everyone in this server", 1, true) ~= nil
			and string.find(reply.message, GameConfig.WorldCycle.NightSeconds .. " s", 1, true) ~= nil,
		"Start Night runs the night for the whole server, and says when day returns", reply.message)
	trail = admin.Audit()
	check(trail[#trail].action == "StartNight" and trail[#trail].admin == ADMIN_A and trail[#trail].target == 0,
		"on the record: the admin and the action, and no target -- it was the whole server")
	reply = admin.Handle(adminB, "StartNight")
	check(not reply.ok and reply.message == "Already night.",
		"Start Night by night: \"Already night.\", and nothing ran", reply.message)
	reply = admin.Handle(adminA, "StartDay", 999999, "junk", "junk")
	check(reply.ok and world.phase == "Day"
			and string.find(reply.message, "restocked (5 of 5 pods)", 1, true) ~= nil,
		"Start Day ends the night with the dawn restock; a target or amount sent with it is not read",
		reply.message)
	reply = admin.Handle(adminB, "StartDay")
	check(not reply.ok and reply.message == "Already day.",
		"Start Day by day: \"Already day.\" -- no second restock", reply.message)
	world.force = "BUSY"
	reply = admin.Handle(adminA, "StartNight")
	check(not reply.ok and string.find(reply.message, "already under way", 1, true) ~= nil,
		"a change already under way: refused, try again in a moment", reply.message)
	world.force = "FAILED"
	reply = admin.Handle(adminA, "StartDay")
	check(not reply.ok and string.find(reply.message, "failed", 1, true) ~= nil,
		"a change that failed says so, and is never a success", reply.message)
	world.force = nil
	trail = admin.Audit()
	check(callsOf("StartNight", worldMark) == 3 and callsOf("StartDay", worldMark) == 3
			and trail[#trail].action == "StartDay" and trail[#trail].admin == ADMIN_A,
		"each press asked once; only the two that changed the world are on the record")

	admin.Config.MinInterval = 1
	task.wait(1.05)
	local press = admin.Handle(adminA, "StartNight")
	local rushed = admin.Handle(adminA, "StartDay")
	check(press.ok and not rushed.ok and string.find(rushed.message, "Too fast", 1, true) ~= nil
			and world.phase == "Night",
		"the one-a-second limit holds for the world buttons too; the rushed press changed nothing",
		rushed.message)
	admin.Config.MinInterval = 0
	world.phase = "Day"

	--==========================================================================
	-- 8b. SECRET ITEMS (2026-10-02): A SECRET INTO THE ADMIN'S OWN BAG
	--
	-- The real CarryService givers (GivePod, GiveHatched with onRecord) and the
	-- real PlayerDataService, on stand-ins; SaveService stubbed as above, so the
	-- saves counted here are MOCKED -- the throwaway-store Play is the real one.
	--==========================================================================
	say("\n-- secret items --")
	local SeedData = require(Shared.SeedData)
	local kept = { cooldown = admin.Config.SecretCooldown, grants = admin.Config.SecretGrants }
	admin.Config.SecretCooldown = 0
	local requests = 0
	local function ask(species, kind, equip, id)
		requests += 1
		return { species = species, kind = kind, equip = equip == true,
			request = id or string.format("spec-secret-%04d", requests) }
	end
	local function rowsOf(p)
		local prof = data.Get(p)
		return if prof then #prof.Held else -1
	end
	local function lastRowOf(p)
		local prof = data.Get(p)
		return if prof and #prof.Held > 0 then prof.Held[#prof.Held] else nil
	end
	local function snapshot()
		return { a = rowsOf(adminA), b = rowsOf(adminB), t = rowsOf(target),
			ta = toolsIn(adminA), tb = toolsIn(adminB), tt = toolsIn(target), saves = #savedPayloads }
	end
	local function same(x, y)
		return x.a == y.a and x.b == y.b and x.t == y.t and x.ta == y.ta and x.tb == y.tb and x.tt == y.tt
			and x.saves == y.saves
	end
	local secretMark = #calls
	local phaseBefore = world.phase

	local s0 = snapshot()
	local strangersRefused = true
	for _, s in ipairs({ target, { UserId = 1 }, { UserId = 5551, Name = "nicnicniccoal" }, nil, "x" }) do
		local r = admin.Handle(s, "GrantSecret", ADMIN_A, ask("snarlbloom", "pod"))
		if r.ok or r.message ~= "Not authorized." then
			strangersRefused = false
		end
	end
	check(strangersRefused and same(s0, snapshot()),
		"a non-admin's GrantSecret -- even naming an admin as the recipient -- is \"Not authorized.\" and grants nothing")

	local forged = {
		admin.Handle(adminA, "GrantSecret", target.UserId, ask("snarlbloom", "pod")),
		admin.Handle(adminA, "GrantSecret", ADMIN_B, ask("petalfawn", "plant")),
		admin.Handle(adminA, "GrantSecret", tostring(ADMIN_A), ask("petalfawn", "plant")),
		admin.Handle(adminA, "GrantSecret", nil, ask("petalfawn", "plant")),
	}
	local forgedRefused = true
	for _, r in ipairs(forged) do
		if r.ok or not string.find(r.message, "only be granted to yourself", 1, true) then
			forgedRefused = false
		end
	end
	check(forgedRefused and same(s0, snapshot()),
		"an admin cannot grant to anybody else -- another player, the other admin, a string id, nobody", forged[1].message)

	local wrongItems = { { "nubkin", "pod" }, { "supernovus", "plant" }, { "Snarlbloom", "pod" }, { "snarlbloom ", "pod" },
		{ "snarlbloom", "seed" }, { "petalfawn", "POD" }, { "petalfawn", "grown" } }
	local wrongRefused = true
	for _, w in ipairs(wrongItems) do
		local r = admin.Handle(adminA, "GrantSecret", ADMIN_A, ask(w[1], w[2]))
		if r.ok or not string.find(r.message, "Only a Snarlbloom or a Petalfawn", 1, true) then
			wrongRefused = false
		end
	end
	check(wrongRefused and same(s0, snapshot()), "any other species or form is refused and nothing is granted")

	local good = function()
		return { species = "snarlbloom", kind = "pod", equip = false, request = "spec-shape-0001" }
	end
	local shapes = { nil, "snarlbloom:pod", { "snarlbloom", "pod" } }
	local missing = good()
	missing.request = nil
	table.insert(shapes, missing)
	local extra = good()
	extra.target = ADMIN_B
	table.insert(shapes, extra)
	local typed = good()
	typed.equip = "yes"
	table.insert(shapes, typed)
	for _, id in ipairs({ "short", string.rep("a", 65), "bad id!", "" }) do
		local r = good()
		r.request = id
		table.insert(shapes, r)
	end
	local malformedRefused = true
	for i = 1, #shapes + 1 do
		local r = admin.Handle(adminA, "GrantSecret", ADMIN_A, shapes[i])
		if r.ok or r.message ~= "Malformed request. Nothing was granted." then
			malformedRefused = false
		end
	end
	check(malformedRefused and same(s0, snapshot()),
		"a malformed request -- not a table, a missing or extra field, a wrong type, a bad request id -- grants nothing")

	admin.Config.SecretGrants = false
	local off = admin.Handle(adminA, "GrantSecret", ADMIN_A, ask("snarlbloom", "pod"))
	admin.Config.SecretGrants = true
	check(not off.ok and string.find(off.message, "switched off", 1, true) and same(s0, snapshot()),
		"with the console's own switch off, nothing is granted", off.message)

	local exact = true
	for _, combo in ipairs({ { "snarlbloom", "pod" }, { "snarlbloom", "plant" }, { "petalfawn", "pod" }, { "petalfawn", "plant" } }) do
		local before = snapshot()
		local r = admin.Handle(adminA, "GrantSecret", ADMIN_A, ask(combo[1], combo[2]))
		local row = lastRowOf(adminA)
		local after = snapshot()
		local fine = r.ok and r.saved == true and string.find(r.message, "saved", 1, true) ~= nil
			and after.a == before.a + 1 and after.ta == before.ta + 1 and after.saves == before.saves + 1
			and after.b == before.b and after.t == before.t
			and row and row.Id == combo[1] and row.Hatched == (combo[2] == "plant") and row.Tier == SeedData.SecretTier
		check(fine, string.format("%s as a %s: exactly one item into the admin's own bag, its saved row at the Secret tier, "
			.. "one save", combo[1], combo[2]), r.message)
		exact = exact and fine
	end

	local once = ask("petalfawn", "pod", false, "spec-repeat-0001")
	local first = admin.Handle(adminA, "GrantSecret", ADMIN_A, once)
	local afterFirst = snapshot()
	local again = admin.Handle(adminA, "GrantSecret", ADMIN_A, once)
	local againCopy = admin.Handle(adminA, "GrantSecret", ADMIN_A, table.clone(once))
	check(first.ok and again.ok and againCopy.ok and string.find(again.message, "Already answered", 1, true) ~= nil
			and same(afterFirst, snapshot()),
		"the same request sent again is answered again and grants nothing more", again.message)

	slowSave = true
	local pendingReply = nil
	local beforePending = snapshot()
	task.spawn(function()
		pendingReply = admin.Handle(adminA, "GrantSecret", ADMIN_A, ask("snarlbloom", "pod", false, "spec-pending-0001"))
	end)
	local during = admin.Handle(adminA, "GrantSecret", ADMIN_A, ask("snarlbloom", "pod", false, "spec-pending-0002"))
	local duringSame = admin.Handle(adminA, "GrantSecret", ADMIN_A, ask("snarlbloom", "pod", false, "spec-pending-0001"))
	task.wait(0.8)
	slowSave = false
	local afterPending = snapshot()
	check(pendingReply ~= nil and pendingReply.ok and not during.ok
			and string.find(during.message, "already being made", 1, true) ~= nil
			and not duringSame.ok and string.find(duringSame.message, "still being made", 1, true) ~= nil
			and afterPending.a == beforePending.a + 1,
		"while a grant is still saving, a second press (new id or the same) is refused: one item, not two",
		during.message .. " / " .. duringSame.message)

	admin.Config.SecretCooldown = 6
	local c1 = admin.Handle(adminB, "GrantSecret", ADMIN_B, ask("petalfawn", "plant"))
	local c2 = admin.Handle(adminB, "GrantSecret", ADMIN_B, ask("petalfawn", "plant"))
	admin.Config.SecretCooldown = 0
	check(c1.ok and not c2.ok and string.find(c2.message, "between Secret grants", 1, true) ~= nil and rowsOf(adminB) == 1,
		"the other admin's first grant works, and a second inside the cooldown is refused", c2.message)

	local fill = {}
	for _ = 1, SAVE.MaxHeld do
		table.insert(fill, { Id = "nubkin", Tier = 1, Hatched = false })
	end
	data.SetHeld(adminB, fill)
	local beforeFull = snapshot()
	local full = admin.Handle(adminB, "GrantSecret", ADMIN_B, ask("snarlbloom", "plant"))
	check(not full.ok and string.find(full.message, string.format("Plant storage full (%d/%d)", SAVE.MaxHeld, SAVE.MaxHeld),
			1, true) ~= nil and same(beforeFull, snapshot()),
		"a full bag refuses with the storage line, and nothing is granted or lost", full.message)
	data.SetHeld(adminB, {})

	local equipBefore = snapshot()
	local equipped = admin.Handle(adminA, "GrantSecret", ADMIN_A, ask("petalfawn", "pod", true))
	local inBag = false
	for _, t in ipairs(adminA._backpack:GetChildren()) do
		if t:IsA("Tool") and t:GetAttribute("SpeciesId") == "petalfawn" then
			inBag = true
		end
	end
	check(equipped.ok and string.find(equipped.message, "Not equipped, kept in your Bag: you have no character right now", 1, true)
			~= nil and inBag and snapshot().a == equipBefore.a + 1,
		"EQUIP NOW on a body that cannot take it: granted, kept in the Bag, and the answer says why", equipped.message)

	saveOk = false
	local unsaved = admin.Handle(adminA, "GrantSecret", ADMIN_A, ask("snarlbloom", "pod"))
	saveOk = true
	check(unsaved.ok and unsaved.saved == false and string.find(unsaved.message, "SAVE HAS NOT LANDED", 1, true) ~= nil,
		"a grant whose save does not land is never reported as saved", unsaved.message)

	local tempAdmin = join("AdminBTemp", ADMIN_B, { Cash = 0 }, "unavailable")
	local beforeTemp = rowsOf(tempAdmin)
	local temporary = admin.Handle(tempAdmin, "GrantSecret", ADMIN_B, ask("snarlbloom", "pod"))
	byId[ADMIN_B] = adminB
	check(not temporary.ok and string.find(temporary.message, "not saving", 1, true) ~= nil
			and rowsOf(tempAdmin) == beforeTemp,
		"a profile that is not saving this session is refused before anything is granted", temporary.message)

	check(callsOf("StartNight", secretMark) == 0 and callsOf("StartDay", secretMark) == 0 and world.phase == phaseBefore,
		"no grant asked for a night or a day")
	local adminSrc = sourceOf(Server.AdminService) or ""
	local grantSrc = string.match(adminSrc, "SECRET ITEMS: A SECRET POD OR GROWN PLANT(.-)ONE REQUEST") or ""
	check(grantSrc ~= "" and not string.find(grantSrc, "NestService", 1, true)
			and not string.find(grantSrc, "SpawnSecret", 1, true) and not string.find(grantSrc, "WorldCycleService", 1, true)
			and not string.find(grantSrc, "FireAllClients", 1, true) and not string.find(grantSrc, "Secret.Enabled", 1, true),
		"the grant never touches a nest, the day and night, a world toast, or the natural-spawn switch")
	check(string.find(grantSrc, "CarryService.GivePod(", 1, true) ~= nil
			and string.find(grantSrc, "CarryService.GiveHatched(", 1, true) ~= nil
			and string.find(grantSrc, "CarryService.EquipIfFree(", 1, true) ~= nil
			and string.find(grantSrc, "PlayerDataService.Save(", 1, true) ~= nil,
		"it grants through CarryService's own givers, equips through EquipIfFree, and saves through PlayerDataService")
	local nestSrc = sourceOf(Server.NestService) or ""
	check(SeedData.SecretTier == 1 and string.find(nestSrc, "BuildPod(species, SeedData.SecretTier,", 1, true) ~= nil,
		"the natural spawn and the grant use the one Secret tier")
	trail = admin.Audit()
	check(trail[#trail] and string.sub(trail[#trail].action, 1, 12) == "GrantSecret:" and trail[#trail].target == ADMIN_A,
		"a grant is on the record, by species and form")
	-- The panel's side, from its source: checked here because the console section below cannot run under
	-- Studio's assistant sandbox (it parents a LocalScript into a stand-in PlayerGui).
	local ui = sourceOf(Server.AdminService:FindFirstChild("AdminConsoleUI")) or ""
	check(string.find(ui, 'InvokeServer("GrantSecret", player.UserId, request, nil)', 1, true) ~= nil
			and string.find(ui, "GRANT TO BAG", 1, true) ~= nil and string.find(ui, "EQUIP NOW", 1, true) ~= nil
			and string.find(ui, "GRANTING…", 1, true) ~= nil and string.find(ui, "HttpService:GenerateGUID(false)", 1, true) ~= nil
			and string.find(ui, "unanswered = request", 1, true) ~= nil,
		"SECRET ITEMS names only the admin as recipient, locks GRANT TO BAG while a grant is pending, and gives every "
			.. "press an id -- resent unchanged when no answer came")
	admin.Config.SecretCooldown = kept.cooldown
	admin.Config.SecretGrants = kept.grants

	--==========================================================================
	-- 9. THE CONSOLE REACHES ADMINS AND NOBODY ELSE
	--==========================================================================
	say("\n-- the console --")
	local function playerGuiFor(p)
		local pg = Instance.new("Folder")
		pg.Name = "PlayerGui"
		pg.Parent = p._holder
		return pg
	end
	local adminGui = playerGuiFor(adminA)
	local built = admin.ProvideConsole(adminA)
	check(built and built.Parent == adminGui and built.Name == "SeedAdmin" and not built.ResetOnSpawn
			and built.IgnoreGuiInset,
		"an admin gets the SeedAdmin gui in their own PlayerGui, kept across respawns")
	check(built and built:FindFirstChild("AdminRequest") and built.AdminRequest:IsA("RemoteFunction")
			and built:FindFirstChild("AdminConsoleUI") and built.AdminConsoleUI:IsA("LocalScript"),
		"holding its RemoteFunction and a copy of the console script")
	local rebuilt = admin.ProvideConsole(adminA)
	local count = 0
	for _, c in ipairs(adminGui:GetChildren()) do
		if c.Name == "SeedAdmin" then
			count += 1
		end
	end
	check(rebuilt and count == 1, "given again, it replaces the old one rather than stacking")
	local strangerGui = playerGuiFor(target)
	check(admin.ProvideConsole(target) == nil and #strangerGui:GetChildren() == 0,
		"a non-admin gets nothing at all")
	local template = Server.AdminService:FindFirstChild("AdminConsoleUI")
	check(template and template:IsA("LocalScript"), "the console script lives inside AdminService, on the server")
	local leaked = {}
	for _, root in ipairs({ StarterPlayer, StarterGui, ReplicatedStorage }) do
		for _, d in ipairs(root:GetDescendants()) do
			if d.Name == "AdminConsoleUI" or d.Name == "SeedAdmin" or d.Name == "AdminRequest" then
				table.insert(leaked, d:GetFullName())
			end
		end
	end
	check(#leaked == 0, "and nothing of it is anywhere a client receives by default", table.concat(leaked, ", "))

	--==========================================================================
	-- 10. THE CLIENT, FROM ITS SOURCE
	--==========================================================================
	say("\n-- the client --")
	local ui = sourceOf(template) or ""
	check(string.find(ui, "layout.admin", 1, true) ~= nil and string.find(ui, "button.Selectable = true", 1, true) ~= nil,
		"the ADMIN button is placed by HudLayout and is selectable for a controller")
	check(string.find(ui, "InvokeServer(action, targetId, amount, typed)", 1, true) ~= nil
			and string.find(ui, "FireServer", 1, true) == nil,
		"it only ever asks, through the one RemoteFunction")
	check(string.find(ui, "\"AddMoney\"", 1, true) and string.find(ui, "\"AddSpeed\"", 1, true)
			and string.find(ui, "\"ResetPlayerProgress\"", 1, true)
			and string.find(ui, "\"StartNight\"", 1, true) and string.find(ui, "\"StartDay\"", 1, true)
			and not string.find(ui, "\"ResetCharacter\"", 1, true),
		"it names the server's five actions, and not the old ResetCharacter")
	check(string.find(ui, "WHOLE SERVER", 1, true) and string.find(ui, "GetAttribute(ATTR.WorldPhase)", 1, true)
			and string.find(ui, "GetAttributeChangedSignal(ATTR.WorldPhase)", 1, true),
		"the day and night buttons are labelled as the whole server's, under the phase read off the clock's attribute")
	check(string.find(ui, "Enum.KeyCode.ButtonB", 1, true) and string.find(ui, "UnbindAction(BACK_ACTION)", 1, true),
		"B steps back on a controller, bound only while the panel is open")
	-- The compact console (2026-10-04) lays itself out from MenuLayout in its own gui (`deck`), on every
	-- change of that gui's size and on every open.
	local openBlock = string.match(ui, "\nsetOpen = function%(want: boolean%)(.-)\nend\n") or ""
	check(string.find(ui, 'deck:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)', 1, true) ~= nil
			and string.find(openBlock, "relayout()", 1, true) ~= nil,
		"the panel is fitted to the screen again when it changes shape and on every open (a phone once kept the "
			.. "desktop height it measured at startup: title and X off the top)")
	check(string.find(ui, "typedMatches()", 1, true) and string.find(ui, "TYPE %s TO CONFIRM", 1, true),
		"the reset asks for the username to be typed, and stays locked until it matches")
	check(string.find(ui, "while true", 1, true) == nil and string.find(ui, "Heartbeat", 1, true) == nil,
		"no loop and no per-frame work")
end)

for _, p in ipairs(joined) do
	p.Parent = Players
	pcall(data.Leave, p)
end
saves.Load, saves.Save, saves.Forget = real.Load, real.Save, real.Forget
plots.SetDesiredLevel, plots.PlotOf = real.SetDesiredLevel, real.PlotOf
data.MountStats = real.MountStats
treads.Unmount, treads.Rebuild = real.Unmount, real.Rebuild
plants.ClearGarden = real.ClearGarden
carry.ForfeitCarry, carry.SyncHeldNow, carry.RefreshWalkSpeed = real.ForfeitCarry, real.SyncHeldNow,
	real.RefreshWalkSpeed
combat.ClearTrap, shop.RefreshTools = real.ClearTrap, real.RefreshTools
cycle.StartNight, cycle.StartDay = real.StartNight, real.StartDay
admin.FindPlayer = real.FindPlayer
admin.Config.MinInterval = real.MinInterval
fixture:Destroy()

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nAdminSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
