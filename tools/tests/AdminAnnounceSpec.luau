--!nocheck
--==============================================================================
-- Steal a Seed :: AdminAnnounceSpec (2026-10-12, the owner's item 10: admin
-- action announcements)
--
--   1. the words: every action's line in the owner's style, a give to oneself
--      and to somebody, the amounts, every mini event's name, nothing for an
--      action that says nothing, every line within the notice's length
--   2. the fold: one key per admin, action and player; a burst counts up, a
--      pause starts afresh, mixed gives named by their form
--   3. AdminService (a copy against stand-ins): each action that happened says
--      its one line, to everybody, once; a refusal, a progress reset, an
--      announcement and a mini event (said by its own path) say nothing here
--   4. a GLOBAL mini event (the real MiniEventService through its seams): the
--      admin named in every server at the event's own announcement, and at an
--      admin's END; the timer's end and a record with no admin say nothing
--   5. naturals never: only AdminService and MiniEventService ever say one
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Notice = require(Shared:WaitForChild("Notice"))
local AdminAnnounce = require(Shared:WaitForChild("AdminAnnounce"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local SpawnCatalog = require(Server:WaitForChild("AdminService"):WaitForChild("SpawnCatalog"))

local CFG = GameConfig.AdminAnnounce
local W = CFG.Words
local ADMIN_A = 4119740186

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
local function has(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end
local function json(v)
	return if v == nil then nil else game:GetService("HttpService"):JSONDecode(
		game:GetService("HttpService"):JSONEncode(v))
end

local fixture = Instance.new("Folder")
fixture.Name = "ZZAdminAnnounceSpecFixture"
fixture.Archivable = false
fixture.Parent = ServerStorage

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the words --")
	--==========================================================================
	local A = "Nicky"
	local lines = {
		{ AdminAnnounce.line(A, { kind = "rain" }), "Nicky started the Rain!" },
		{ AdminAnnounce.line(A, { kind = "thunder" }), "Nicky summoned a Thunderstorm!" },
		{ AdminAnnounce.line(A, { kind = "weatherend" }), "Nicky ended the Rain" },
		{ AdminAnnounce.line(A, { kind = "weatherend", thunder = true }), "Nicky ended the Thunderstorm" },
		{ AdminAnnounce.line(A, { kind = "miststart" }), "Nicky started the Enchanted Mist!" },
		{ AdminAnnounce.line(A, { kind = "mistend" }), "Nicky ended the Enchanted Mist" },
		{ AdminAnnounce.line(A, { kind = "night" }), "Nicky made it night!" },
		{ AdminAnnounce.line(A, { kind = "day" }), "Nicky brought the day back!" },
		{ AdminAnnounce.line(A, { kind = "mini", mode = "podrush" }), "Nicky started POD RUSH!" },
		{ AdminAnnounce.line(A, { kind = "miniend", mode = "podrush" }), "Nicky ended POD RUSH" },
		{ AdminAnnounce.line(A, { kind = "spawn", target = "Rin", words = "a Colossal Snarlbloom pod" }),
			"Nicky gave Rin a Colossal Snarlbloom pod!" },
		{ AdminAnnounce.line(A, { kind = "spawn", own = true, words = "a Colossal Snarlbloom pod" }),
			"Nicky spawned a Colossal Snarlbloom pod!" },
		{ AdminAnnounce.line(A, { kind = "money", target = "Rin", amount = 1e6 }), "Nicky gave Rin $1M" },
		{ AdminAnnounce.line(A, { kind = "speed", target = "Rin", amount = 500e3 }), "Nicky gave Rin 500K Speed" },
		{ AdminAnnounce.line(A, { kind = "money", own = true, amount = 2.5e6 }), "Nicky gave themselves $2.5M" },
	}
	local wrong = {}
	for _, pair in ipairs(lines) do
		if pair[1] ~= pair[2] then
			table.insert(wrong, tostring(pair[1]) .. " ~= " .. pair[2])
		end
	end
	check(#wrong == 0, "every action's line, in the owner's style", table.concat(wrong, " | "))
	local modes = 0
	for id, mode in pairs(GameConfig.MiniEvent.Modes) do
		if AdminAnnounce.line(A, { kind = "mini", mode = id }) == string.format("Nicky started %s!", mode.Name) then
			modes += 1
		end
	end
	local total = 0
	for _ in pairs(GameConfig.MiniEvent.Modes) do
		total += 1
	end
	check(modes == total and total >= 5, "every mini event by its own name", modes .. " of " .. total)
	check(AdminAnnounce.line(A, { kind = "reset" }) == nil and AdminAnnounce.line(A, { kind = "announce" }) == nil
			and AdminAnnounce.line(A, { kind = "spawn" }) == nil and AdminAnnounce.line(A, { kind = "money", amount = 0 }) == nil
			and AdminAnnounce.line(A, { kind = "mini", mode = "nope" }) == nil,
		"nothing for a reset, an announcement, an unknown action or a give of nothing")
	check(AdminAnnounce.nameOf({ Name = "nicnicniccoal", DisplayName = "Nicky" }) == "Nicky"
			and AdminAnnounce.nameOf({ Name = "nicnicniccoal", DisplayName = "" }) == "nicnicniccoal"
			and AdminAnnounce.nameOf({}) == W.Somebody,
		"names are display names (as a rebirth's and SERVER LUCK's lines), the username where there is none")
	-- The longest line: two 20-letter names and the longest species at its
	-- biggest size, a whole Bag of them.
	local longest, longestName = "", ""
	for _, species in pairs(SeedData.ById) do
		local words = SpawnCatalog.phrase(species, SeedData.TierCount, "plant", GameConfig.Save.MaxHeld)
		if #words > #longest then
			longest, longestName = words, species.Id
		end
	end
	local twenty = string.rep("W", 20)
	local worst = AdminAnnounce.line(twenty, { kind = "spawn", target = twenty, words = longest }) or ""
	local cut = Notice.readServerNotice({ title = worst })
	check(#worst > 0 and cut ~= nil and #worst <= Notice.ServerTitleMax,
		"the longest give fits a notice's line whole", string.format("%d of %d: %s", #worst, Notice.ServerTitleMax, worst))

	--==========================================================================
	say("\n-- 2. the fold --")
	--==========================================================================
	check(AdminAnnounce.key(7, "spawn", 9) == "admin:7:spawn:9" and AdminAnnounce.key(7, "night") == "admin:7:night"
			and AdminAnnounce.key(7, "spawn", 9) ~= AdminAnnounce.key(8, "spawn", 9)
			and AdminAnnounce.key(7, "spawn", 9) ~= AdminAnnounce.key(7, "money", 9),
		"one key per admin, action and player")
	local f = AdminAnnounce.fold(nil, 100, { kind = "spawn", quantity = 2, species = "petalpip", size = 5, form = "pod" })
	f = AdminAnnounce.fold(f, 110, { kind = "spawn", quantity = 3, species = "petalpip", size = 5, form = "pod" })
	check(f.quantity == 5 and not f.mixed and AdminAnnounce.spawnWords(f, "5 Giant Petalpip pods") == "5 Giant Petalpip pods",
		"a burst of the same thing counts up under its own name")
	local g = AdminAnnounce.fold(f, 115, { kind = "spawn", quantity = 1, species = "nubkin", size = 5, form = "pod" })
	local h = AdminAnnounce.fold(g, 118, { kind = "spawn", quantity = 1, species = "nubkin", size = 5, form = "plant" })
	check(AdminAnnounce.spawnWords(g, "x") == "6 pods" and AdminAnnounce.spawnWords(h, "x") == "7 items",
		"different things fold by their form, or as items")
	local m = AdminAnnounce.fold(nil, 0, { kind = "money", amount = 1e6 })
	m = AdminAnnounce.fold(m, 10, { kind = "money", amount = 1e6 })
	local fresh = AdminAnnounce.fold(m, 10 + CFG.FoldSeconds + 1, { kind = "money", amount = 1e6 })
	check(m.amount == 2e6 and fresh.amount == 1e6, "amounts add up; a pause past FoldSeconds starts afresh")

	--==========================================================================
	say("\n-- 3. AdminService --")
	--==========================================================================
	local fakePlayers = {}
	local function stand(id, name, shown)
		return { UserId = id, Name = name, DisplayName = shown, Parent = fakePlayers,
			FindFirstChildOfClass = function()
				return nil
			end }
	end
	local admin = stand(ADMIN_A, "nicnicniccoal", "Nicky")
	local rin = stand(90000000001, "RinTest", "Rin")
	local stranger = stand(90000000002, "Stranger", "Stranger")
	local byUserId = { [admin.UserId] = admin, [rin.UserId] = rin }
	local profiles = { [admin] = { Cash = 0, Speed = 0 }, [rin] = { Cash = 0, Speed = 0 } }
	local world = { night = false, weather = nil, mistOn = false, refuseWeather = false, refuseMist = false }
	local said, miniCalls = {}, 0
	local siblings = {
		PlayerDataService = {
			Get = function(p)
				return profiles[p]
			end,
			IsReady = function()
				return true
			end,
			IsPersistent = function()
				return true
			end,
			Save = function()
				return true
			end,
			ResetProgress = function()
				return true
			end,
		},
		EconomyService = {
			PayReward = function(p, n)
				profiles[p].Cash += n
				return true
			end,
		},
		TreadmillService = {
			PayReward = function(p, n)
				profiles[p].Speed += n
				return true
			end,
			Unmount = function() end,
			Rebuild = function() end,
			TierOf = function()
				return 1
			end,
		},
		PlotService = {
			PlotOf = function()
				return nil
			end,
			SetDesiredLevel = function() end,
		},
		PlantService = {
			ClearGarden = function()
				return 0
			end,
		},
		CarryService = {
			GivePod = function()
				return true
			end,
			GiveHatched = function()
				return true
			end,
			HeldRoom = function()
				return 30, 0, true
			end,
			SyncHeldNow = function() end,
			ForfeitCarry = function() end,
			RefreshWalkSpeed = function() end,
		},
		CombatService = { ClearTrap = function() end },
		WeaponShopService = { RefreshTools = function() end },
		WorldCycleService = {
			StartNight = function()
				if world.night then
					return false, "ALREADY_NIGHT"
				end
				world.night = true
				return true
			end,
			StartDay = function()
				if not world.night then
					return false, "ALREADY_DAY"
				end
				world.night = false
				return true, nil, 10, 12
			end,
		},
		AnnouncementService = {
			Send = function()
				return true, "Sent.", "a1"
			end,
		},
		WeatherService = {
			State = function()
				return world.weather
			end,
			StartRain = function()
				if world.refuseWeather or world.weather then
					return false, "Rain is already falling."
				end
				world.weather = { mode = "rain" }
				return true, "Rain started."
			end,
			StartThunderstorm = function()
				if world.refuseWeather or world.weather then
					return false, "Rain is already falling."
				end
				world.weather = { mode = "thunder" }
				return true, "Thunderstorm started."
			end,
			EndRain = function()
				if not world.weather then
					return true, "Nothing is falling.", false
				end
				world.weather = nil
				return true, "Ended.", true
			end,
		},
		MiniEventService = {
			StartGlobal = function()
				miniCalls += 1
				return true, "Started."
			end,
			EndGlobal = function()
				miniCalls += 1
				return true, "Ended.", true
			end,
		},
		EnchantedMistService = {
			Hooks = {
				now = function()
					return 1000
				end,
			},
			AdminStart = function()
				if world.refuseMist then
					return false, "NIGHT"
				end
				world.mistOn = true
				return true
			end,
			AdminEnd = function()
				if not world.mistOn then
					return false, "NOT_ACTIVE"
				end
				world.mistOn = false
				return true
			end,
			EndsAt = function()
				return 1300
			end,
		},
	}
	local module = Server:WaitForChild("AdminService")
	local chunk, lerr = loadstring(module.Source, "=AdminService")
	assert(chunk, tostring(lerr))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, "AdminService asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	local scriptStandIn = { Name = "AdminService", Parent = parent }
	function scriptStandIn:WaitForChild(name)
		return module:WaitForChild(name)
	end
	function scriptStandIn:FindFirstChild(name)
		return module:FindFirstChild(name)
	end
	local fakeGame = {}
	function fakeGame:GetService(name)
		if name == "Players" then
			return fakePlayers
		end
		return game:GetService(name)
	end
	local outerRequire = require
	setfenv(chunk, setmetatable({
		game = fakeGame,
		script = scriptStandIn,
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) }))
	local Admin = chunk()
	Admin.Config.MinInterval = 0
	Admin.Config.SpawnCooldown = 0
	Admin.FindPlayer = function(id)
		return byUserId[id]
	end
	Admin.TellPlayer = function() end
	Admin.TellEveryone = function(title, key)
		table.insert(said, { title = title, key = key })
	end
	local function act(sender, ...)
		table.clear(said)
		return Admin.Handle(sender, ...)
	end
	local function one(line, key)
		return #said == 1 and said[1].title == line and (key == nil or said[1].key == key)
	end

	local r = act(stranger, "StartNight")
	check(not r.ok and #said == 0, "somebody off the allowlist: refused, and nothing said")
	r = act(admin, "StartNight")
	check(r.ok and one("Nicky made it night!", "admin:" .. ADMIN_A .. ":night"),
		"START NIGHT: one line to everybody, by display name, its own key", said[1] and said[1].title)
	r = act(admin, "StartNight")
	check(not r.ok and #said == 0, "asking for the night it already is: refused, nothing said")
	r = act(admin, "StartDay")
	check(r.ok and one("Nicky brought the day back!"), "START DAY", said[1] and said[1].title)
	r = act(admin, "Weather", "start", 120)
	check(r.ok and one("Nicky started the Rain!"), "the Rain", said[1] and said[1].title)
	r = act(admin, "Weather", "end")
	check(r.ok and one("Nicky ended the Rain"), "and its end", said[1] and said[1].title)
	r = act(admin, "Weather", "thunder", 120)
	local thunder = one("Nicky summoned a Thunderstorm!")
	r = act(admin, "Weather", "end")
	check(thunder and one("Nicky ended the Thunderstorm"), "a Thunderstorm, and its end by its own name",
		said[1] and said[1].title)
	r = act(admin, "Weather", "end")
	check(#said == 0, "ending weather that is not falling says nothing")
	r = act(admin, "Weather", "start", 3)
	world.refuseWeather = true
	local refused = act(admin, "Weather", "start", 120)
	world.refuseWeather = false
	check(not r.ok and not refused.ok and #said == 0, "a refused start (a bad duration, the weather's own no) says nothing")
	r = act(admin, "Mist", "start")
	check(r.ok and one("Nicky started the Enchanted Mist!"), "START MIST", said[1] and said[1].title)
	r = act(admin, "Mist", "end")
	check(r.ok and one("Nicky ended the Enchanted Mist"), "END MIST", said[1] and said[1].title)
	world.refuseMist = true
	r = act(admin, "Mist", "start")
	world.refuseMist = false
	check(not r.ok and #said == 0, "a refused Mist says nothing")
	r = act(admin, "AddMoney", rin.UserId, 1e6)
	check(r.ok and one("Nicky gave Rin $1M", "admin:" .. ADMIN_A .. ":money:" .. rin.UserId), "ADD MONEY: a give",
		said[1] and said[1].title)
	r = act(admin, "AddMoney", rin.UserId, 1e6)
	check(r.ok and one("Nicky gave Rin $2M", "admin:" .. ADMIN_A .. ":money:" .. rin.UserId),
		"a second give to the same player folds into the same line, counted up", said[1] and said[1].title)
	r = act(admin, "AddSpeed", admin.UserId, 500e3)
	check(r.ok and one("Nicky gave themselves 500K Speed"), "ADD SPEED to oneself", said[1] and said[1].title)
	r = act(admin, "AddMoney", rin.UserId, -5)
	check(not r.ok and #said == 0, "a refused grant says nothing")
	local request = { species = "petalpip", form = "pod", size = 5, quantity = 5, request = "spec-announce-0001" }
	r = act(admin, "Spawn", rin.UserId, request, rin.Name)
	local words = SpawnCatalog.phrase(SeedData.Get("petalpip"), 5, "pod", 5)
	check(r.ok and one(string.format("Nicky gave Rin %s!", words), "admin:" .. ADMIN_A .. ":spawn:" .. rin.UserId),
		"SPAWN to somebody: the give, with its quantity", said[1] and said[1].title)
	local own = { species = "petalpip", form = "pod", size = 5, quantity = 1, request = "spec-announce-0002" }
	r = act(admin, "Spawn", admin.UserId, own, nil)
	check(r.ok and one(string.format("Nicky spawned %s!", SpawnCatalog.phrase(SeedData.Get("petalpip"), 5, "pod", 1))),
		"SPAWN to oneself", said[1] and said[1].title)
	r = act(admin, "Spawn", rin.UserId, { species = "petalpip", form = "pod", size = 5, quantity = 5,
		request = "spec-announce-0001" }, rin.Name)
	check(#said == 0, "the same request again gives nothing more, and says nothing")
	r = act(admin, "Spawn", rin.UserId, { species = "nope", form = "pod", size = 5, quantity = 1,
		request = "spec-announce-0003" }, rin.Name)
	check(not r.ok and #said == 0, "a refused spawn says nothing")
	r = act(admin, "ResetPlayerProgress", rin.UserId, nil, rin.Name)
	check(#said == 0, "a progress reset says nothing to everybody (it would shame a player)", r.message)
	r = act(admin, "Announce", "server", "Hello", nil)
	check(#said == 0, "an announcement is already one: nothing more")
	local before = miniCalls
	r = act(admin, "MiniEvent", "party", 90)
	local startSaid = #said
	local endR = act(admin, "MiniEvent", "end")
	check(miniCalls == before + 2 and startSaid == 0 and #said == 0,
		"a mini event says nothing here: its own path says it, in every server")

	--==========================================================================
	say("\n-- 4. a GLOBAL mini event --")
	--==========================================================================
	local MiniEventService = require(Server.MiniEventService)
	local RealAdmin = require(Server.AdminService)
	local storeValue = nil
	local attrs = Instance.new("Folder")
	attrs.Parent = fixture
	local now = 1790000000
	local sent = {}
	MiniEventService.Reset()
	MiniEventService.useShared({
		scope = "global",
		note = "spec store",
		ns = "place_spec_announce",
		update = function(transform)
			local v = transform(json(storeValue))
			if v ~= nil then
				storeValue = json(v)
			end
			return true, nil
		end,
		read = function()
			return true, json(storeValue)
		end,
		publish = function()
			return true, nil
		end,
		subscribe = function()
			return true, nil
		end,
	})
	MiniEventService.useClock(function()
		return now
	end)
	MiniEventService.usePlayers(function()
		return {}
	end)
	MiniEventService.useBroadcast(function(action, payload)
		table.insert(sent, { action = action, payload = payload })
	end)
	MiniEventService.useWorld(attrs, attrs)
	local keptInterval = RealAdmin.Config.MinInterval
	RealAdmin.Config.MinInterval = 0
	local okRun, runErr = pcall(function()
		local function adminLines()
			local found = {}
			for _, m in ipairs(sent) do
				if m.action == Notice.ServerNotice and type(m.payload) == "table" then
					table.insert(found, m.payload)
				end
			end
			return found
		end
		local started = RealAdmin.Handle(admin, "MiniEvent", "party", 90)
		local early = #adminLines()
		now += GameConfig.MiniEvent.AnnounceDelaySeconds + 0.1
		MiniEventService.Step(now)
		local lines1 = adminLines()
		local mode = GameConfig.MiniEvent.Modes.party.Name
		check(started.ok and early == 0 and #lines1 == 1 and lines1[1].title == string.format("Nicky started %s!", mode)
				and lines1[1].key == "admin:" .. ADMIN_A .. ":mini" and lines1[1].icon == CFG.Icon,
			"the admin is named at the event's own announcement, in this server as in every other", lines1[1] and lines1[1].title)
		table.clear(sent)
		RealAdmin.Handle(admin, "MiniEvent", "end")
		local lines2 = adminLines()
		check(#lines2 == 1 and lines2[1].title == string.format("Nicky ended %s", mode),
			"and an admin's END, in every server it reaches", lines2[1] and lines2[1].title)
		-- Another server's record arriving: the same line here, from the record.
		table.clear(sent)
		now += 5
		local remote = {
			v = (json(storeValue) or {}).v, ns = "place_spec_announce", id = "remoteEvent0001", rev = 999,
			mode = "party", startedAt = now, endsAt = now + 60, by = 90000000009, byName = "RemoteAdmin",
			byShown = "Remy", state = "running", endedIds = {},
		}
		local applied = MiniEventService.Apply(remote, "message")
		now += GameConfig.MiniEvent.AnnounceDelaySeconds + 0.1
		MiniEventService.Step(now)
		local lines3 = adminLines()
		check(applied and #lines3 == 1 and lines3[1].title == string.format("Remy started %s!", mode),
			"an event another server started: its admin named here too, from the record", lines3[1] and lines3[1].title)
		-- Its timer ends it: nothing more is said.
		table.clear(sent)
		now += 61
		MiniEventService.Step(now)
		check(#adminLines() == 0, "an event's timer ending it says nothing new")
		-- A record from before this change (no display name): no admin line.
		table.clear(sent)
		now += 5
		local old = table.clone(remote)
		old.id, old.rev, old.byShown, old.startedAt, old.endsAt = "oldRecord000001", 1001, nil, now, now + 60
		MiniEventService.Apply(old, "message")
		now += GameConfig.MiniEvent.AnnounceDelaySeconds + 0.1
		MiniEventService.Step(now)
		check(#adminLines() == 0, "a record with no admin's name says nothing")
		local bad = table.clone(remote)
		bad.id, bad.rev, bad.byShown = "badRecord0000001", 1002, string.rep("x", 41)
		check(not MiniEventService.ValidRecord(bad), "an admin's name longer than 40 is no valid record")
	end)
	MiniEventService.Reset()
	MiniEventService.useWorld(nil, nil)
	MiniEventService.useShared(nil)
	MiniEventService.useClock(nil)
	MiniEventService.usePlayers(nil)
	MiniEventService.useBroadcast(nil)
	RealAdmin.Config.MinInterval = keptInterval
	check(okRun, "the global path ran", runErr)

	--==========================================================================
	say("\n-- 5. naturals never --")
	--==========================================================================
	local sayers = {}
	for _, m in ipairs(Server:GetDescendants()) do
		if m:IsA("LuaSourceContainer") and has(m.Source, "AdminAnnounce") then
			table.insert(sayers, m.Name == "init" and m.Parent.Name or m.Name)
		end
	end
	table.sort(sayers)
	check(table.concat(sayers, ",") == "AdminService,MiniEventService",
		"only AdminService and MiniEventService ever say one: never the weather lottery, a Pod Rush's news, the Mist's "
			.. "schedule, nightfall, nest stock or a purchase", table.concat(sayers, ","))
	local adminSrc = Server:WaitForChild("AdminService").Source
	local _, calls = string.gsub(adminSrc, "\n%s*announce%(admin, ", "")
	check(calls == 7, "AdminService says a line from seven places, each right after its record", calls)
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
fixture:Destroy()
say(string.format("\nAdminAnnounceSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
