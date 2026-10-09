--!nocheck
--==============================================================================
-- Steal a Seed :: AdminSpec
--
-- The admin console's three accounts, on the server: who may ask, what may be
-- asked, and what each action does to a profile. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("AdminSpec"))
--
-- The REAL AdminService, PlayerDataService, EconomyService, TreadmillService and
-- CarryService, fresh-required, with stand-in players joined the way
-- AlmanacClaimSpec joins them: SaveService's Load and Save are stubbed -- so no
-- DataStore is read or written, and no real profile is touched -- and the calls
-- a progress reset makes into the world (the garden, the plot, the mill, the
-- bag, the trap, the respawn) are recorded rather than performed, so their
-- ORDER can be checked. The allowlisted UserIds appear here only on stand-in
-- tables.
--
-- Not here: the round trip over the RemoteFunction, the panel (AdminConsoleSpec
-- has its arithmetic), and a real respawn rebuilding a real bag (Play, on a
-- throwaway store). Start Night and Start Day reach stand-ins for
-- WorldCycleService's two doors here -- this is about who may press them and
-- what they are told; CycleSpec runs the real transitions. The weather's three
-- doors (WeatherService) are stand-ins too, for the same reason: RainEventSpec
-- runs the real event, terrain and all.
--==============================================================================
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
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
local WeatherService = require(Server.WeatherService)
local AdminService = require(Server.AdminService)
local SpawnCatalog = require(Server.AdminService.SpawnCatalog)

local SAVE = GameConfig.Save
-- The owner, Teambarnze825, and TappedYou (the third, 2026-10-07).
local ADMIN_A, ADMIN_B, ADMIN_C = 4119740186, 11607308004, 1139904972

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
local weatherSvc: any = WeatherService
local real = {
	StartNight = cycle.StartNight, StartDay = cycle.StartDay,
	StartRain = weatherSvc.StartRain, StartThunderstorm = weatherSvc.StartThunderstorm, EndRain = weatherSvc.EndRain,
	Load = saves.Load, Save = saves.Save, Forget = saves.Forget,
	SetDesiredLevel = plots.SetDesiredLevel, PlotOf = plots.PlotOf,
	MountStats = data.MountStats,
	Unmount = treads.Unmount, Rebuild = treads.Rebuild,
	ClearGarden = plants.ClearGarden,
	ForfeitCarry = carry.ForfeitCarry, SyncHeldNow = carry.SyncHeldNow,
	RefreshWalkSpeed = carry.RefreshWalkSpeed, GivePod = carry.GivePod,
	ClearTrap = combat.ClearTrap, RefreshTools = shop.RefreshTools,
	FindPlayer = admin.FindPlayer, TellPlayer = admin.TellPlayer, MinInterval = admin.Config.MinInterval,
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
-- WeatherService's three doors, answering the way the real ones do: one event
-- at a time, and an END with nothing running harmless and ending nothing.
local sky = { mode = nil }
weatherSvc.StartRain = function(by, seconds)
	note("StartRain", by, seconds)
	if sky.mode then
		return false, "Rain is already falling. Nothing changed."
	end
	sky.mode = "rain"
	return true, "Rain started."
end
weatherSvc.StartThunderstorm = function(by, seconds)
	note("StartThunderstorm", by, seconds)
	if sky.mode then
		return false, "A thunderstorm is already raging. Nothing changed."
	end
	sky.mode = "thunder"
	return true, "Thunderstorm started."
end
weatherSvc.EndRain = function(by)
	note("EndRain", by)
	if not sky.mode then
		return true, "No rain or thunderstorm is running. Nothing changed.", false
	end
	sky.mode = nil
	return true, "Ended.", true
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
-- What a player was told (AdminService.TellPlayer), instead of the wire.
local told = {}
admin.TellPlayer = function(p, title, detail, key)
	table.insert(told, { p = p, title = title, detail = detail, key = key })
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
	local adminC = join("AdminC", ADMIN_C, { Cash = 0, Speed = 0 })
	local target, profile = join("SpecTarget", 5551, { Cash = 1000, Speed = 2000 })

	--==========================================================================
	-- 1. WHO MAY ASK: THREE NUMERIC USER IDS
	--==========================================================================
	say("-- the allowlist --")
	check(admin.IsAdmin(adminA) and admin.IsAdmin(adminB) and admin.IsAdmin(adminC),
		"all three verified UserIds are admins: nicnicniccoal, Teambarnze825 and TappedYou")
	local strangers = {
		{ UserId = 1, Name = "nicnicniccoal" },
		{ UserId = 5551, Name = "Teambarnze825", DisplayName = "nicnicniccoal" },
		{ UserId = 5551, Name = "TappedYou", DisplayName = "Villager" },
		{ UserId = 1139904973 }, { UserId = 1139904971 }, { UserId = ADMIN_C + 0.5 }, { UserId = tostring(ADMIN_C) },
		{ UserId = 0 }, { UserId = -ADMIN_A }, { UserId = ADMIN_A + 0.5 },
		{ UserId = tostring(ADMIN_A) }, { Name = "nicnicniccoal" }, { Name = "TappedYou" }, {}, "nicnicniccoal",
		ADMIN_A, ADMIN_C, nil,
	}
	local anyAdmin = false
	for _, s in ipairs(strangers) do
		if admin.IsAdmin(s) then
			anyAdmin = true
		end
	end
	check(not anyAdmin, "nobody else -- a fourth id beside TappedYou's included: not by username, display name, a "
		.. "string id, a negated or fractional id, or a bare number")
	local src = sourceOf(Server.AdminService) or ""
	local list = string.match(src, "local ALLOWED[^\n]*=%s*{(.-)}")
	local ids = {}
	for id in string.gmatch(list or "", "%[(%d+)%]") do
		table.insert(ids, tonumber(id))
	end
	table.sort(ids)
	check(#ids == 3 and ids[1] == ADMIN_C and ids[2] == ADMIN_A and ids[3] == ADMIN_B,
		"the allowlist in the source holds exactly 1139904972, 4119740186 and 11607308004", table.concat(ids, ","))
	check(admin.IsOwner(adminA) and not admin.IsOwner(adminB) and not admin.IsOwner(adminC),
		"the owner is nicnicniccoal alone: TappedYou and Teambarnze825 are admins, not the owner")
	local isAdminBody = string.match(src, "function AdminService%.IsAdmin(.-)\nend") or ""
	check(isAdminBody ~= "" and not string.find(isAdminBody, "Name", 1, true)
			and not string.find(isAdminBody, "Attribute", 1, true)
			and not string.find(isAdminBody, "Rank", 1, true),
		"IsAdmin reads the UserId and nothing else")
	check((GameConfig :: any).Admin == nil and (GameConfig :: any).Debug == nil
			and (GameConfig.Remotes :: any).AdminRequest == nil,
		"nothing about admins is in GameConfig, which every client can read")
	-- THE WEATHER IS ALL THREE ADMINS' (owner, 2026-10-07): each starts the rain,
	-- stops it, starts a thunderstorm and stops that, and each change is audited
	-- under the admin who made it.
	local weatherBad = {}
	for _, who in ipairs({ adminA, adminB, adminC }) do
		local from = #calls
		local auditFrom = #admin.Audit()
		local rain = admin.Handle(who, "Weather", "start", 300)
		local stopRain = admin.Handle(who, "Weather", "end")
		local thunder = admin.Handle(who, "Weather", "thunder", 300)
		local stopThunder = admin.Handle(who, "Weather", "end")
		local asked = callsOf("StartRain", from) == 1 and callsOf("StartThunderstorm", from) == 1
			and callsOf("EndRain", from) == 2
		local entries = admin.Audit()
		local mine, actions = true, {}
		for i = auditFrom + 1, #entries do
			table.insert(actions, entries[i].action)
			mine = mine and entries[i].admin == who.UserId
		end
		local auditedAll = table.concat(actions, ",") == "Weather:start:300,Weather:end,Weather:thunder:300,Weather:end"
		if not (rain.ok and stopRain.ok and thunder.ok and stopThunder.ok and asked and mine and auditedAll) then
			table.insert(weatherBad, string.format("%s: %s / %s / %s / %s; audit %s", who.Name, rain.message,
				stopRain.message, thunder.message, stopThunder.message, table.concat(actions, ",")))
		end
	end
	check(#weatherBad == 0, "the weather is all three admins': nicnicniccoal, Teambarnze825 and TappedYou each start "
		.. "the rain, stop it, start a thunderstorm and stop it -- each change in the audit under who made it",
		table.concat(weatherBad, " | "))
	local fourth = { UserId = 1139904973, Name = "NotAnAdmin" }
	local fromFourth = #calls
	local refusedFourth = admin.Handle(fourth, "Weather", "start", 300)
	check(not refusedFourth.ok and refusedFourth.message == "Not authorized." and callsOf("StartRain", fromFourth) == 0
			and sky.mode == nil,
		"a fourth id is refused before WeatherService is asked", refusedFourth.message)
	local adminSrcCode = string.gsub(src, "%-%-[^\n]*", "")
	check(string.find(adminSrcCode, "IsOwner(admin)", 1, true) == nil and string.find(adminSrcCode, "Owner only", 1, true) == nil,
		"and the weather has no owner gate left on the server: the allowlist is its door, as for every other action")
	local titleSrc = sourceOf(Server:FindFirstChild("OwnerTitleService")) or ""
	check(string.find(titleSrc, "if not AdminService.HasTitle(player) then", 1, true) ~= nil
			and string.find(titleSrc, "IsAdmin(", 1, true) == nil,
		"and so is the rainbow ADMIN title: OwnerTitleService asks HasTitle, never IsAdmin")
	-- The title (2026-10-09, the owner: "add admin title to michael"; "yes, Teambarnze825 is Michael"): the owner's and
	-- Teambarnze825's, by UserId; a lookalike name gets none; TappedYou and anybody else none; and Teambarnze825 is
	-- still not the owner.
	local titleOwner = { UserId = 4119740186, Name = "nicnicniccoal" }
	local titleMichael = { UserId = 11607308004, Name = "Teambarnze825" }
	local titleTapped = { UserId = 1139904972, Name = "TappedYou" }
	local titleLookalike = { UserId = 90000000044, Name = "Teambarnze825" }
	check(admin.HasTitle(titleOwner) and admin.HasTitle(titleMichael) and not admin.HasTitle(titleTapped)
			and not admin.HasTitle(fourth) and not admin.HasTitle(titleLookalike)
			and admin.IsOwner(titleOwner) and not admin.IsOwner(titleMichael),
		"the ADMIN title is the owner's and Teambarnze825's by UserId (a lookalike name gets none), not TappedYou's or "
			.. "anybody else's; Teambarnze825 is still not the owner")
	-- And OwnerTitleService builds it so: on stand-in bodies (a Model and its Head), never a real character.
	local TitleService = require(Server.OwnerTitleService)
	local function standInBody()
		local body = Instance.new("Model")
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Anchored = true
		head.Parent = body
		return body, head
	end
	local michaelBody, michaelHead = standInBody()
	local tappedBody, tappedHead = standInBody()
	local lookalikeBody, lookalikeHead = standInBody()
	local builtMichael = TitleService.Apply(titleMichael, michaelBody)
	local builtTapped = TitleService.Apply(titleTapped, tappedBody)
	local builtLookalike = TitleService.Apply(titleLookalike, lookalikeBody)
	local TITLE_NAME = GameConfig.OwnerTitle.Name
	check(builtMichael ~= nil and michaelHead:FindFirstChild(TITLE_NAME) == builtMichael and builtTapped == nil
			and tappedHead:FindFirstChild(TITLE_NAME) == nil and builtLookalike == nil
			and lookalikeHead:FindFirstChild(TITLE_NAME) == nil,
		"OwnerTitleService builds the ADMIN title on Teambarnze825's head, and none on TappedYou's or a lookalike's")
	michaelBody:Destroy()
	tappedBody:Destroy()
	lookalikeBody:Destroy()
	local trafficSrc = sourceOf(Server:FindFirstChild("TrafficLogService")) or ""
	check(string.find(trafficSrc, "admin.IsAdmin", 1, true) ~= nil,
		"staff everywhere admins already are: the traffic log leaves out whoever IsAdmin names, now three")

	--==========================================================================
	-- 2. A FORGED REQUEST FROM ANYBODY ELSE CHANGES NOTHING
	--==========================================================================
	say("\n-- forged requests --")
	local before = #calls
	local refusedAll = true
	for _, s in ipairs({ target, { UserId = 1 }, { UserId = 5551, Name = "nicnicniccoal" }, nil, "x" }) do
		for _, action in ipairs({ "AddMoney", "AddSpeed", "ResetPlayerProgress", "StartNight", "StartDay", "Spawn" }) do
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
	reply = admin.Handle(adminC, "AddMoney", target.UserId, 1)
	check(reply.ok and profile.Cash == 6001, "TappedYou adds cash like any admin", reply.message)
	profile.Cash = 6000

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
	-- 4. AMOUNTS, UP TO THE SAVE LIMITS (2026-10-07)
	--==========================================================================
	say("\n-- amounts --")
	check(admin.Config.MaxMoney == SAVE.MaxCash and admin.Config.MaxSpeed == SAVE.MaxSpeedScore
			and admin.Config.MaxMoney == 1e15 and admin.Config.MaxSpeed == 1e15,
		"one request may add up to the save limits: 1e15 cash and 1e15 Speed")
	local configBlock = string.match(src, "AdminService%.Config = {(.-)\n}") or ""
	check(string.find(configBlock, "MaxMoney = SAVE.MaxCash", 1, true) ~= nil
			and string.find(configBlock, "MaxSpeed = SAVE.MaxSpeedScore", 1, true) ~= nil
			and string.find(configBlock, "1e15", 1, true) == nil and string.find(configBlock, "1e12", 1, true) == nil,
		"and they are READ from GameConfig.Save, never copied")
	local bad = { 0, -5, 1.5, 0 / 0, math.huge, -math.huge, "1000", true, {}, nil,
		admin.Config.MaxMoney + 1, 2 ^ 53, 1e15 - 0.5 }
	local allRefused = true
	for _, value in ipairs(bad) do
		local r1 = admin.Handle(adminA, "AddMoney", target.UserId, value)
		local r2 = admin.Handle(adminA, "AddSpeed", target.UserId, value)
		if r1.ok or r2.ok then
			allRefused = false
		end
	end
	check(allRefused and profile.Cash == 6000 and profile.Speed == 5000,
		"zero, negative, fractional, NaN, both infinities, strings, nil, 1e15 + 1 and 2^53 are all refused, and "
			.. "nothing moved")
	local over = admin.Handle(adminA, "AddMoney", target.UserId, 1e15 + 1)
	check(not over.ok and string.find(over.message, "1,000,000,000,000,000", 1, true) ~= nil,
		"the refusal shows the new limit", over.message)
	local richest, richestProfile = join("SpecRichest", 5570, { Cash = 0, Speed = 0 })
	reply = admin.Handle(adminA, "AddMoney", richest.UserId, 1e15)
	local speedReply = admin.Handle(adminC, "AddSpeed", richest.UserId, 1e15)
	check(reply.ok and reply.added == 1e15 and richestProfile.Cash == 1e15 and speedReply.ok
			and speedReply.added == 1e15 and richestProfile.Speed == 1e15
			and string.find(reply.message, "$1,000,000,000,000,000", 1, true) ~= nil,
		"1e15 cash and 1e15 Speed land whole in one request each, said in full", reply.message)
	profile.Cash = 0
	reply = admin.Handle(adminA, "AddMoney", target.UserId, admin.Config.MaxMoney)
	check(reply.ok and reply.added == admin.Config.MaxMoney, "the limit itself is allowed", reply.message)
	profile.Cash = 6000

	--==========================================================================
	-- 5. ACTIONS AND TARGETS
	--==========================================================================
	say("\n-- actions and targets --")
	local unknown = true
	for _, action in ipairs({ "ResetCharacter", "SetCash", "Kick", "GrantSecret", "", 42, nil, {} }) do
		if admin.Handle(adminA, action, target.UserId, 1000, target.Name).ok then
			unknown = false
		end
	end
	check(unknown, "anything but ACTIONS is refused -- including the old ResetCharacter and the old GrantSecret")
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
	-- 8b. SPAWN (2026-10-07): ANY PLANT OR POD, INTO ANYBODY'S BAG
	--
	-- The real CarryService givers (GivePod, GiveHatched with onRecord) and the
	-- real PlayerDataService, on stand-ins; SaveService stubbed as above, so the
	-- saves counted here are MOCKED -- the throwaway-store Play is the real one.
	--==========================================================================
	say("\n-- spawn --")
	local kept = { cooldown = admin.Config.SpawnCooldown, spawning = admin.Config.Spawning }
	admin.Config.SpawnCooldown = 0
	local requests = 0
	local function ask(species, form, size, quantity, id)
		requests += 1
		return { species = species, form = form, size = size, quantity = quantity or 1,
			request = id or string.format("spec-spawn-%05d", requests) }
	end
	local function rowsOf(who)
		local prof = data.Get(who)
		return if prof then #prof.Held else -1
	end
	local function snapshot()
		return { a = rowsOf(adminA), b = rowsOf(adminB), c = rowsOf(adminC), t = rowsOf(target),
			ta = toolsIn(adminA), tb = toolsIn(adminB), tc = toolsIn(adminC), tt = toolsIn(target),
			saves = #savedPayloads }
	end
	local function same(x, y)
		return x.a == y.a and x.b == y.b and x.c == y.c and x.t == y.t and x.ta == y.ta and x.tb == y.tb
			and x.tc == y.tc and x.tt == y.tt and x.saves == y.saves
	end
	local function clearBag(who)
		for _, c in ipairs({ who._backpack, who.Character }) do
			for _, x in ipairs(c:GetChildren()) do
				if x:IsA("Tool") then
					x:Destroy()
				end
			end
		end
		data.SetHeld(who, {})
	end
	local function newTools(who)
		local found = {}
		for _, c in ipairs({ who._backpack, who.Character }) do
			for _, x in ipairs(c:GetChildren()) do
				if x:IsA("Tool") then
					table.insert(found, x)
				end
			end
		end
		return found
	end
	local spawnMark = #calls
	local phaseBefore = world.phase
	for _, who in ipairs({ adminA, adminB, adminC, target }) do
		clearBag(who)
	end

	local s0 = snapshot()
	local strangersRefused = true
	for _, s in ipairs({ target, { UserId = 1 }, { UserId = 5551, Name = "nicnicniccoal" }, { UserId = 1139904973 },
		nil, "x" }) do
		local r = admin.Handle(s, "Spawn", ADMIN_A, ask("nubkin", "pod", 1))
		if r.ok or r.message ~= "Not authorized." then
			strangersRefused = false
		end
	end
	check(strangersRefused and same(s0, snapshot()),
		"a non-admin's Spawn -- even naming an admin as the target -- is \"Not authorized.\" and gives nothing")

	local good = function()
		return { species = "nubkin", form = "pod", size = 1, quantity = 1, request = "spec-shape-0001" }
	end
	local shapes = { nil, "nubkin:pod", { "nubkin", "pod", 1, 1 } }
	for _, field in ipairs({ "species", "form", "size", "quantity", "request" }) do
		local r = good()
		r[field] = nil
		table.insert(shapes, r)
	end
	local extra = good()
	extra.target = ADMIN_B
	table.insert(shapes, extra)
	local equip = good()
	equip.equip = true
	table.insert(shapes, equip)
	for field, value in pairs({ species = 5, form = true, size = "7", quantity = "3" }) do
		local r = good()
		r[field] = value
		table.insert(shapes, r)
	end
	for _, id in ipairs({ "short", string.rep("a", 65), "bad id!", "", 12345678 }) do
		local r = good()
		r.request = id
		table.insert(shapes, r)
	end
	local malformedRefused = true
	for i = 1, #shapes + 1 do
		local r = admin.Handle(adminA, "Spawn", ADMIN_A, shapes[i])
		if r.ok or r.message ~= "Malformed request. Nothing was spawned." then
			malformedRefused = false
		end
	end
	check(malformedRefused and same(s0, snapshot()),
		"a malformed request -- not a table, a missing or extra field (the old EQUIP NOW too), a wrong type, a bad "
			.. "request id -- gives nothing")

	local unknownRefused = true
	for _, id in ipairs({ "unicorn", "Nubkin", "nubkin ", "", "SNARLBLOOM", string.rep("a", 100), "rainpod4" }) do
		local r = admin.Handle(adminA, "Spawn", ADMIN_A, ask(id, "pod", 1))
		if r.ok or not string.find(r.message, "No species has that id", 1, true) then
			unknownRefused = false
		end
	end
	check(unknownRefused and same(s0, snapshot()),
		"an id SeedData does not know -- by case, a space, a pod's id instead of a creature's -- gives nothing")

	local formsRefused = true
	for _, form in ipairs({ "seed", "POD", "grown", "Plant", "" }) do
		local r = admin.Handle(adminA, "Spawn", ADMIN_A, ask("nubkin", form, 1))
		if r.ok or not string.find(r.message, "POD or GROWN PLANT", 1, true) then
			formsRefused = false
		end
	end
	check(formsRefused and same(s0, snapshot()), "a form other than pod or plant gives nothing")

	local badSizes = { { "nubkin", 0 }, { "nubkin", 8 }, { "nubkin", 1.5 }, { "nubkin", 0 / 0 }, { "nubkin", -1 },
		{ "nubkin", math.huge }, { "snarlbloom", 7 }, { "petalfawn", 2 }, { "puddlepod", 2 },
		{ "puddlepod_colossal", 1 }, { "tempestoak", 7 }, { "thundermaw", 3 }, { "dustthorn", 2 },
		{ "heliothorn", 7 }, { "squallsnapper", 0 }, { "torrentacle", 8 } }
	local sizesRefused, sizeLeak = true, {}
	for _, b in ipairs(badSizes) do
		local r = admin.Handle(adminA, "Spawn", ADMIN_A, ask(b[1], "pod", b[2]))
		if r.ok or not string.find(r.message, "does not come in that size", 1, true) then
			sizesRefused = false
			table.insert(sizeLeak, b[1] .. "@" .. tostring(b[2]))
		end
	end
	check(sizesRefused and same(s0, snapshot()),
		"a size the species does not come in gives nothing: off the ladder, fractional, NaN, a Secret, Pod 1, 2 or 3, "
			.. "an Invite reward away from its one size", table.concat(sizeLeak, ", "))

	local qtyRefused = true
	for _, q in ipairs({ 0, -1, 1.5, SAVE.MaxHeld + 1, 0 / 0, math.huge }) do
		local r = admin.Handle(adminA, "Spawn", ADMIN_A, ask("nubkin", "pod", 1, q))
		if r.ok or not string.find(r.message, "quantity must be a whole number", 1, true) then
			qtyRefused = false
		end
	end
	check(qtyRefused and same(s0, snapshot()), "a quantity outside 1 .. " .. SAVE.MaxHeld .. " gives nothing")

	admin.Config.Spawning = false
	local off = admin.Handle(adminA, "Spawn", ADMIN_A, ask("nubkin", "pod", 1))
	admin.Config.Spawning = true
	check(not off.ok and string.find(off.message, "switched off", 1, true) and same(s0, snapshot()),
		"with the console's own switch off, nothing is spawned", off.message)
	check(admin.Config.Spawning == true and kept.spawning == true and GameConfig.Secret.Enabled == true,
		"the switch is on by default, on the server; natural Secret spawning is its own switch, on since 2026-10-09")

	local targetsRefused = true
	for _, id in ipairs({ "5551", 0, -5551, 5551.5, nil, {} }) do
		local r = admin.Handle(adminA, "Spawn", id, ask("nubkin", "pod", 1), "SpecTarget")
		if r.ok or not string.find(r.message, "Choose a player first", 1, true) then
			targetsRefused = false
		end
	end
	local gone = admin.Handle(adminA, "Spawn", 999999, ask("nubkin", "pod", 1), "Nobody")
	local left = admin.Handle(adminA, "Spawn", 5552, ask("nubkin", "pod", 1), "SpecLeaver")
	check(targetsRefused and not gone.ok and string.find(gone.message, "no longer in this server", 1, true)
			and not left.ok and same(s0, snapshot()),
		"a target that is not somebody in this server -- a bad id, a stranger, a leaver -- gets nothing", gone.message)

	-- ANOTHER PLAYER: confirmed by their username, and told.
	local unconfirmed = admin.Handle(adminA, "Spawn", target.UserId, ask("lanterncap", "pod", 7, 3))
	local misnamed = admin.Handle(adminA, "Spawn", target.UserId, ask("lanterncap", "pod", 7, 3), "SpecTargt")
	local otherAdmin = admin.Handle(adminA, "Spawn", ADMIN_B, ask("lanterncap", "pod", 7, 3))
	check(not unconfirmed.ok and string.find(unconfirmed.message, "needs the confirm", 1, true)
			and not misnamed.ok and not otherAdmin.ok and same(s0, snapshot()) and #told == 0,
		"giving to anybody but yourself -- another admin too -- needs their username, the console's confirm",
		unconfirmed.message)
	local beforeGift = snapshot()
	local gift = admin.Handle(adminA, "Spawn", target.UserId, ask("lanterncap", "pod", 7, 3), "  spectarget ")
	local afterGift = snapshot()
	local giftRows = data.Get(target).Held
	local allLantern = #giftRows == 3
	for _, row in ipairs(giftRows) do
		if row.Id ~= "lanterncap" or row.Tier ~= 7 or row.Hatched ~= false then
			allLantern = false
		end
	end
	check(gift.ok and gift.saved == true and gift.given == 3 and afterGift.t == beforeGift.t + 3
			and afterGift.tt == beforeGift.tt + 3 and afterGift.a == beforeGift.a and allLantern
			and afterGift.saves == beforeGift.saves + 1
			and string.find(gift.message, "Gave 3 Colossal Lanterncap pods to SpecTarget and saved", 1, true) ~= nil,
		"confirmed, three Colossal Lanterncap pods go into THEIR bag, three saved rows, ONE save", gift.message)
	local tell = told[#told]
	check(#told == 1 and tell and tell.p == target and tell.title == "An admin gave you 3 Colossal Lanterncap pods!"
			and type(tell.key) == "string",
		"and they are told: \"An admin gave you 3 Colossal Lanterncap pods!\"", tell and tell.title)
	trail = admin.Audit()
	local entry = trail[#trail]
	check(entry and entry.action == "Spawn" and entry.admin == ADMIN_A and entry.target == 5551
			and entry.species == "lanterncap" and entry.size == 7 and entry.form == "pod" and entry.quantity == 3,
		"on the record: who, the target, the species, the size, the form and how many")
	local ownTold = #told
	local own = admin.Handle(adminC, "Spawn", ADMIN_C, ask("nubkin", "plant", 2))
	check(own.ok and own.saved == true and #told == ownTold and rowsOf(adminC) == 1
			and string.find(own.message, "into your Bag", 1, true) ~= nil,
		"TappedYou spawns into their own bag like any admin; nobody else is told", own.message)
	clearBag(target)
	clearBag(adminC)

	-- EVERY SPECIES AND POD TYPE, IN EVERY SIZE IT COMES IN, AS A POD AND GROWN.
	local combos, wrongCombos = 0, {}
	local podsReached = {}
	local started = os.clock()
	for _, species in ipairs(SpawnCatalog.all()) do
		for _, size in ipairs(SpawnCatalog.sizesOf(species)) do
			for _, form in ipairs({ "pod", "plant" }) do
				combos += 1
				clearBag(adminA)
				local savesBefore = #savedPayloads
				local r = admin.Handle(adminA, "Spawn", ADMIN_A, ask(species.Id, form, size, 1))
				local rows = data.Get(adminA).Held
				local tools = newTools(adminA)
				local row, t = rows[1], tools[1]
				local fine = r.ok and r.saved == true and #rows == 1 and #tools == 1 and #savedPayloads == savesBefore + 1
					and row.Id == species.Id and row.Tier == size and row.Hatched == (form == "plant")
					and t:GetAttribute("SpeciesId") == species.Id and t:GetAttribute("CarryingKg") == size
					and (t:GetAttribute("Hatched") == true) == (form == "plant")
				if not fine then
					table.insert(wrongCombos, string.format("%s@%d/%s: %s", species.Id, size, form, tostring(r.message)))
				end
				local pod = SpawnCatalog.podOf(species, size)
				if pod and form == "pod" then
					podsReached[pod.Id] = true
				end
			end
		end
	end
	clearBag(adminA)
	local allPods = true
	for podId in pairs(SeedData.RainPods) do
		if not podsReached[podId] then
			allPods = false
		end
	end
	local speciesCount = 0
	for _ in pairs(SeedData.ById) do
		speciesCount += 1
	end
	check(#wrongCombos == 0 and #SpawnCatalog.all() == speciesCount,
		string.format("every one of the %d species, in every size it comes in, as a pod and grown: %d spawns, each "
			.. "exactly one Tool and one saved row of that species and size, one save (%.1f s)", speciesCount, combos,
			os.clock() - started), table.concat(wrongCombos, "; "))
	check(allPods and podsReached.rainpod4 and podsReached.rainpod5,
		"every Rain pod type was spawned: rainpod1, 2 and 3, rainpod4 (Tiny .. Titan) and rainpod5 (Colossal)")

	-- A SPAWNED INVITE REWARD IS UNSELLABLE; A SPAWNED RAIN POD KEEPS ITS EVENT RULES.
	local invite = admin.Handle(adminA, "Spawn", ADMIN_A, ask("dustthorn", "plant", SeedData.InviteTier))
	local inviteRow = data.Get(adminA).Held[1]
	local inviteTool = newTools(adminA)[1]
	check(invite.ok and inviteRow and inviteRow.Id == "dustthorn" and inviteTool
			and SeedData.Sellable(SeedData.Get(inviteTool:GetAttribute("SpeciesId"))) == false
			and SeedData.Sellable(SeedData.Get(inviteRow.Id)) == false,
		"a spawned Invite reward is the reward itself: its row and Tool name Dustthorn, which no stall buys")
	clearBag(adminA)
	local rainWrong = {}
	for _, species in ipairs(SeedData.RainSpecies) do
		for _, size in ipairs(SpawnCatalog.sizesOf(species)) do
			local pod = SpawnCatalog.podOf(species, size)
			local shell = SeedData.PodFormOf(species, size)
			local wantShell = if species.PodForms then species.PodForms[size] else species.Pod
			local fine = pod ~= nil and SeedData.GrowSecondsFor(species, size) == pod.GrowSeconds
				and shell == wantShell and species.SkipHatchRoll == true and species.Event == "rain"
				and SeedData.RainPodOf(species) ~= nil and table.find(pod.Species, species.Id) ~= nil
				and (pod.Tier == size or (pod.Tiers and (pod.Tiers[size] or 0) > 0))
				and (if pod.Id == "rainpod4" then size < SeedData.TierCount elseif pod.Id == "rainpod5"
					then size == SeedData.TierCount else true)
			if not fine then
				table.insert(rainWrong, species.Id .. "@" .. size)
			end
		end
	end
	check(#rainWrong == 0, "a spawned Rain pod keeps its event rules: its pod's growth time, its own shell (the size's "
		.. "own for the second family), the skipped roll; rainpod4 only below Colossal, rainpod5 only at it",
		table.concat(rainWrong, ", "))

	-- THE BAG'S ROOM: for the whole quantity, or nothing -- in the room of the
	-- form asked for (2026-10-09: pods have their own, Save.MaxPods, and plants
	-- keep Save.MaxHeld).
	local fill = {}
	for _ = 1, SAVE.MaxHeld do
		table.insert(fill, { Id = "nubkin", Tier = 1, Hatched = true })
	end
	data.SetHeld(adminB, fill)
	local beforeFull = snapshot()
	local full = admin.Handle(adminB, "Spawn", ADMIN_B, ask("snarlbloom", "plant", SeedData.SecretTier))
	check(not full.ok and string.find(full.message, "Not enough room", 1, true) ~= nil
			and string.find(full.message, string.format("(%d/%d plants)", SAVE.MaxHeld, SAVE.MaxHeld), 1, true) ~= nil
			and same(beforeFull, snapshot()),
		"a full bag refuses with the storage line, and nothing is given or lost", full.message)
	local nearlyFull = {}
	for _ = 1, SAVE.MaxPods - 2 do
		table.insert(nearlyFull, { Id = "nubkin", Tier = 1, Hatched = false })
	end
	-- And the 24 plants beside them take none of the pods' room.
	for _, row in ipairs(fill) do
		table.insert(nearlyFull, table.clone(row))
	end
	data.SetHeld(adminB, nearlyFull)
	local beforeShort = snapshot()
	local short = admin.Handle(adminB, "Spawn", ADMIN_B, ask("nubkin", "pod", 3, 3))
	check(not short.ok and string.find(short.message, "2 free", 1, true) ~= nil and same(beforeShort, snapshot()),
		"room for 2 and 3 asked: refused whole -- not two of the three", short.message)
	data.SetHeld(adminB, {})

	-- ONE ITEM CANNOT BE GIVEN: THOSE ALREADY GIVEN GO BACK.
	local gives = 0
	carry.GivePod = function(...)
		gives += 1
		if gives == 2 then
			return false
		end
		return real.GivePod(...)
	end
	local recordedSync = carry.SyncHeldNow
	carry.SyncHeldNow = function(who, consumed)
		note("SyncHeldNow", who, consumed and #consumed or 0)
		real.SyncHeldNow(who, consumed)
	end
	local beforeRollback = snapshot()
	local broken = admin.Handle(adminA, "Spawn", ADMIN_A, ask("nubkin", "pod", 2, 3))
	carry.GivePod = real.GivePod
	carry.SyncHeldNow = recordedSync
	check(not broken.ok and string.find(broken.message, "nothing was spawned", 1, true) ~= nil
			and same(beforeRollback, snapshot()) and gives == 2,
		"the second of three cannot be given: the first is taken back with its row, and nothing at all is spawned",
		broken.message)

	-- THE SAME REQUEST TWICE.
	local once = ask("petalfawn", "pod", SeedData.SecretTier, 1, "spec-repeat-0001")
	local firstSpawn = admin.Handle(adminA, "Spawn", ADMIN_A, once)
	local afterFirst = snapshot()
	local again = admin.Handle(adminA, "Spawn", ADMIN_A, once)
	local againCopy = admin.Handle(adminA, "Spawn", ADMIN_A, table.clone(once))
	check(firstSpawn.ok and again.ok and againCopy.ok and string.find(again.message, "Already answered", 1, true) ~= nil
			and same(afterFirst, snapshot()),
		"the same request sent again is answered again and gives nothing more", again.message)
	clearBag(adminA)

	slowSave = true
	local pendingReply = nil
	local beforePending = snapshot()
	task.spawn(function()
		pendingReply = admin.Handle(adminA, "Spawn", ADMIN_A, ask("snarlbloom", "pod", 1, 1, "spec-pending-0001"))
	end)
	local during = admin.Handle(adminA, "Spawn", ADMIN_A, ask("snarlbloom", "pod", 1, 1, "spec-pending-0002"))
	local duringSame = admin.Handle(adminA, "Spawn", ADMIN_A, ask("snarlbloom", "pod", 1, 1, "spec-pending-0001"))
	task.wait(0.8)
	slowSave = false
	local afterPending = snapshot()
	check(pendingReply ~= nil and pendingReply.ok and not during.ok
			and string.find(during.message, "already being made", 1, true) ~= nil
			and not duringSame.ok and string.find(duringSame.message, "still being made", 1, true) ~= nil
			and afterPending.a == beforePending.a + 1,
		"while a spawn is still saving, a second press (new id or the same) is refused: one item, not two",
		during.message .. " / " .. duringSame.message)
	clearBag(adminA)

	admin.Config.SpawnCooldown = 6
	local c1 = admin.Handle(adminB, "Spawn", ADMIN_B, ask("petalfawn", "plant", 1))
	local c2 = admin.Handle(adminB, "Spawn", ADMIN_B, ask("petalfawn", "plant", 1))
	admin.Config.SpawnCooldown = 0
	check(c1.ok and not c2.ok and string.find(c2.message, "between spawns", 1, true) ~= nil and rowsOf(adminB) == 1,
		"the other admin's first spawn works, and a second inside the cooldown is refused", c2.message)
	clearBag(adminB)

	saveOk = false
	local unsaved = admin.Handle(adminA, "Spawn", ADMIN_A, ask("snarlbloom", "pod", 1))
	saveOk = true
	check(unsaved.ok and unsaved.saved == false and string.find(unsaved.message, "SAVE HAS NOT LANDED", 1, true) ~= nil,
		"a spawn whose save does not land is never reported as saved", unsaved.message)
	clearBag(adminA)

	local tempAdmin = join("AdminBTemp", ADMIN_B, { Cash = 0 }, "unavailable")
	local beforeTemp = rowsOf(tempAdmin)
	local temporary = admin.Handle(tempAdmin, "Spawn", ADMIN_B, ask("snarlbloom", "pod", 1))
	byId[ADMIN_B] = adminB
	check(not temporary.ok and string.find(temporary.message, "not saving", 1, true) ~= nil
			and rowsOf(tempAdmin) == beforeTemp,
		"a profile that is not saving this session is refused before anything is spawned", temporary.message)
	local loadingTarget = admin.Handle(adminA, "Spawn", 5553, ask("nubkin", "pod", 1), "SpecLoading")
	check(not loadingTarget.ok and string.find(loadingTarget.message, "has not loaded", 1, true) ~= nil,
		"a target whose profile has not loaded gets nothing", loadingTarget.message)

	check(callsOf("StartNight", spawnMark) == 0 and callsOf("StartDay", spawnMark) == 0 and world.phase == phaseBefore,
		"no spawn asked for a night or a day")
	local adminSrc = sourceOf(Server.AdminService) or ""
	local spawnSrc = string.match(adminSrc, "SPAWN: ANY PLANT OR POD, INTO ANYBODY'S BAG(.-)THE WEATHER: EVERY ADMIN'S") or ""
	-- What RUNS, without the comments that explain what it leaves alone.
	local spawnCode = string.gsub(spawnSrc, "%-%-[^\n]*", "")
	check(spawnSrc ~= "" and not string.find(spawnCode, "NestService", 1, true)
			and not string.find(spawnCode, "SpawnSecret", 1, true) and not string.find(spawnCode, "WorldCycleService", 1, true)
			and not string.find(spawnCode, "FireAllClients", 1, true) and not string.find(spawnCode, "Secret.Enabled", 1, true),
		"a spawn never touches a nest, the day and night, a world toast, or the natural-spawn switch")
	local _, saveCalls = string.gsub(spawnSrc, "PlayerDataService%.Save%(", "")
	check(string.find(spawnSrc, "CarryService.GivePod(", 1, true) ~= nil
			and string.find(spawnSrc, "CarryService.GiveHatched(", 1, true) ~= nil
			and string.find(spawnSrc, "CarryService.SyncHeldNow(", 1, true) ~= nil
			and string.find(spawnSrc, "SpawnCatalog.allows(", 1, true) ~= nil and saveCalls == 1,
		"it gives through CarryService's own givers, takes back through SyncHeldNow, checks sizes with SpawnCatalog, "
			.. "and saves exactly once")
	admin.Config.SpawnCooldown = kept.cooldown
	admin.Config.Spawning = kept.spawning

	--==========================================================================
	-- 9. THE CONSOLE REACHES ADMINS AND NOBODY ELSE
	--==========================================================================
	say("\n-- the console --")
	local function playerGuiFor(who)
		local pg = Instance.new("Folder")
		pg.Name = "PlayerGui"
		pg.Parent = who._holder
		return pg
	end
	local adminGui = playerGuiFor(adminA)
	local built = admin.ProvideConsole(adminA)
	check(built and built.Parent == adminGui and built.Name == "SeedAdmin" and not built.ResetOnSpawn
			and built.IgnoreGuiInset,
		"an admin gets the SeedAdmin gui in their own PlayerGui, kept across respawns")
	check(built and built:FindFirstChild("AdminRequest") and built.AdminRequest:IsA("RemoteFunction")
			and built:FindFirstChild("AdminConsoleUI") and built.AdminConsoleUI:IsA("LocalScript")
			and built:FindFirstChild("SpawnCatalog") and built.SpawnCatalog:IsA("ModuleScript")
			and built:FindFirstChild("ConsoleModel") and built.ConsoleModel:IsA("ModuleScript"),
		"holding its RemoteFunction, a copy of the console script and its two modules")
	check(built and built:GetAttribute("MaxMoney") == SAVE.MaxCash and built:GetAttribute("MaxSpeed") == SAVE.MaxSpeedScore
			and built:GetAttribute("Spawning") == true
			and built:GetAttribute("SpawnCooldown") == admin.Config.SpawnCooldown
			and built:GetAttribute("SpawnAnswerSeconds") == admin.Config.SpawnAnswerSeconds
			and built:GetAttribute("MinInterval") == admin.Config.MinInterval,
		"told the limits, the switch and its waits (how it draws, not what it may do)")
	local cGui = playerGuiFor(adminC)
	local builtC = admin.ProvideConsole(adminC)
	check(builtC and builtC.Parent == cGui and builtC:GetAttribute("IsOwner") == nil and built:GetAttribute("IsOwner") == nil,
		"TappedYou gets the console too, the same as the owner's: no console is told who the owner is any more -- "
			.. "the weather is every admin's (2026-10-07) and the title is OwnerTitleService's")
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
			if d.Name == "AdminConsoleUI" or d.Name == "SeedAdmin" or d.Name == "AdminRequest"
				or d.Name == "SpawnCatalog" or d.Name == "ConsoleModel" then
				table.insert(leaked, d:GetFullName())
			end
		end
	end
	check(#leaked == 0, "and nothing of it -- script, remote or module -- is anywhere a client receives by default",
		table.concat(leaked, ", "))
	local roster = game:GetService("HttpService"):JSONDecode(admin.RosterLine())
	check(type(roster) == "table", "the target bar's roster is one JSON line of everybody here")

	--==========================================================================
	-- 10. THE CLIENT, FROM ITS SOURCE (the redesign: AdminConsoleSpec has the rest)
	--==========================================================================
	say("\n-- the client --")
	local ui = sourceOf(template) or ""
	local modelSrc = sourceOf(Server.AdminService:FindFirstChild("ConsoleModel")) or ""
	check(string.find(ui, "layout.admin", 1, true) ~= nil and string.find(ui, "button.Selectable = true", 1, true) ~= nil,
		"the ADMIN button is placed by HudLayout and is selectable for a controller")
	check(string.find(ui, "remote:InvokeServer(a[1], a[2], a[3], a[4])", 1, true) ~= nil
			and string.find(ui, "FireServer", 1, true) == nil,
		"it only ever asks, through the one RemoteFunction")
	check(string.find(modelSrc, "\"AddMoney\"", 1, true) and string.find(modelSrc, "\"AddSpeed\"", 1, true)
			and string.find(modelSrc, "\"ResetPlayerProgress\"", 1, true)
			and string.find(modelSrc, "\"StartNight\"", 1, true) and string.find(modelSrc, "\"StartDay\"", 1, true)
			and string.find(modelSrc, "\"Spawn\"", 1, true) and string.find(modelSrc, "\"Weather\"", 1, true)
			and string.find(modelSrc, "\"MiniEvent\"", 1, true) and string.find(modelSrc, "\"Announce\"", 1, true)
			and not string.find(modelSrc, "\"ResetCharacter\"", 1, true)
			and not string.find(modelSrc .. ui, "GrantSecret", 1, true),
		"it names the server's actions (through ConsoleModel) -- SPAWN, not the old GrantSecret or ResetCharacter")
	check(string.find(ui, "WHOLE SERVER", 1, true) and string.find(ui, "GetAttribute(ATTR.WorldPhase)", 1, true)
			and string.find(ui, "ATTR.WorldPhase, ATTR.WorldPhaseEndsAt", 1, true),
		"the day and night buttons are labelled as the whole server's, under the phase read off the clock's attribute")
	check(string.find(ui, "Enum.KeyCode.ButtonB", 1, true) and string.find(ui, "UnbindAction(BACK_ACTION)", 1, true),
		"B steps back on a controller, bound only while the panel is open")
	-- The console lays itself out from ConsoleModel in its own gui (`deck`), on every change of that gui's size
	-- and on every open.
	local openBlock = string.match(ui, "\nsetOpen = function%(want: boolean%)(.-)\nend\n") or ""
	check(string.find(ui, 'deck:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)', 1, true) ~= nil
			and string.find(openBlock, "relayout()", 1, true) ~= nil,
		"the panel is fitted to the screen again when it changes shape and on every open")
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
carry.GivePod = real.GivePod
combat.ClearTrap, shop.RefreshTools = real.ClearTrap, real.RefreshTools
cycle.StartNight, cycle.StartDay = real.StartNight, real.StartDay
weatherSvc.StartRain, weatherSvc.StartThunderstorm, weatherSvc.EndRain = real.StartRain, real.StartThunderstorm,
	real.EndRain
admin.FindPlayer = real.FindPlayer
admin.TellPlayer = real.TellPlayer
admin.Config.MinInterval = real.MinInterval
fixture:Destroy()

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nAdminSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
