--!nocheck
--==============================================================================
-- Steal a Seed :: AdminMistSpec (2026-10-12, the owner's item 12: the Enchanted
-- Mist's admin tools)
--
--   1. the words: each tool's line in the owner's style; a lowering of a
--      player's Dewberries and a progress reset to 0 say nothing; a pod's line
--      never names what is inside; every line within the notice's length
--   2. AdminService (a copy against stand-ins, with a copy of the REAL
--      MysteryPodService behind it): every tool -- START MIST NOW's length,
--      MAKE ELIGIBLE NOW, a BERRY BURST, MOSSKEEPER SAYS, a player's
--      Dewberries, their progress, a Mysterious Pod, READY NOW -- checked,
--      recorded, said (or not); and refused: off the allowlist, a bad target,
--      out of range, no running Mist for a burst, a full Bag for a pod, a pod
--      for somebody else without their username, words the filter could not
--      check; SPAWN refuses what SpawnCatalog does not list (the raw shell)
--   3. the services' own parts: EnchantedMistService's lengths and MAKE
--      ELIGIBLE NOW (a copy, on a fake clock), the berries' BURST and their
--      stats (a copy), the Mosskeeper's line and MysteryPodService's chosen
--      grant and MakeReady (the real modules, through their hooks)
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Notice = require(Shared:WaitForChild("Notice"))
local AdminAnnounce = require(Shared:WaitForChild("AdminAnnounce"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")

local ADMIN_A = 4119740186
local POOL = EnchantedMistData.Pool.Entries
local PER = EnchantedMistData.BerriesPerPod
local CAP = EnchantedMistData.CarryCap
local STATES = EnchantedMistConfig.States

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
	return type(text) == "string" and string.find(text, needle, 1, true) ~= nil
end
-- Whether a line names any of the pod's creatures.
local function namesCreature(text)
	for _, entry in ipairs(POOL) do
		if has(string.lower(text or ""), string.lower(entry.Name)) or has(string.lower(text or ""), entry.Id) then
			return entry.Name
		end
	end
	return nil
end

local fixture = Instance.new("Folder")
fixture.Name = "ZZAdminMistSpecFixture"
fixture.Archivable = false
fixture.Parent = ServerStorage

local restores = {}
local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the words --")
	--==========================================================================
	local A = "Nicky"
	local lines = {
		{ AdminAnnounce.line(A, { kind = "dewberries", amount = 5, target = "Rin" }), "Nicky gave Rin 5 Dewberries!" },
		{ AdminAnnounce.line(A, { kind = "progress", amount = 7, target = "Rin" }),
			string.format("Nicky set Rin's Dewberry progress to 7/%d", PER) },
		{ AdminAnnounce.line(A, { kind = "mistpod", target = "Rin" }), "Nicky gave Rin a Mysterious Pod!" },
		{ AdminAnnounce.line(A, { kind = "mistready", target = "Rin" }), "Nicky made Rin's Mysterious Pods ready!" },
		{ AdminAnnounce.line(A, { kind = "burst" }), "Nicky dropped a Dewberry burst!" },
		{ AdminAnnounce.line(A, { kind = "misteligible" }), "Nicky made the Enchanted Mist eligible!" },
	}
	local wrong = {}
	for _, pair in ipairs(lines) do
		if pair[1] ~= pair[2] then
			table.insert(wrong, tostring(pair[1]) .. " ~= " .. pair[2])
		end
	end
	check(#wrong == 0, "each tool says its line: Dewberries given, progress set, a Mysterious Pod given, pods made "
		.. "ready, a burst, the Mist eligible -- by display name, to oneself or to somebody", table.concat(wrong, "; "))
	check(AdminAnnounce.line(A, { kind = "dewberries", amount = 0, target = "Rin" }) == nil
			and AdminAnnounce.line(A, { kind = "progress", amount = 0, target = "Rin" }) == nil,
		"nothing for a give of no Dewberries, nor for a progress reset to 0 (the owner: silent)")
	local leaked = nil
	for _, pair in ipairs(lines) do
		leaked = leaked or namesCreature(pair[1])
	end
	check(leaked == nil, "no line names a creature: what is inside a pod is never said", leaked)
	local long = string.rep("W", 20)
	local longest = 0
	for _, what in ipairs({ { kind = "progress", amount = 9, target = long }, { kind = "dewberries", amount = 5,
		target = long }, { kind = "mistready", target = long }, { kind = "mistpod", target = long } }) do
		longest = math.max(longest, utf8.len(AdminAnnounce.line(long, what) :: string) or 0)
	end
	check(longest <= Notice.ServerTitleMax, "the longest, with two 20-letter names, fits the notice whole", longest)

	--==========================================================================
	say("\n-- 2. AdminService (a copy against stand-ins) --")
	--==========================================================================
	local NOW = 1790000000
	local fakePlayers = {}
	local function body(at)
		local root = { Position = at, IsA = function(_, class)
			return class == "BasePart"
		end }
		local humanoid = { Health = 100 }
		return {
			FindFirstChildOfClass = function(_, class)
				return if class == "Humanoid" then humanoid else nil
			end,
			FindFirstChild = function(_, name)
				return if name == "HumanoidRootPart" then root else nil
			end,
		}
	end
	local function stand(id, name, shown, at)
		return { UserId = id, Name = name, DisplayName = shown, Parent = fakePlayers, Character = if at then body(at) else nil,
			FindFirstChildOfClass = function()
				return nil
			end }
	end
	local ADMIN_AT = Vector3.new(12, 3, -40)
	local admin = stand(ADMIN_A, "nicnicniccoal", "Nicky", ADMIN_AT)
	local rin = stand(90000000001, "RinTest", "Rin", nil)
	local stranger = stand(90000000002, "Stranger", "Stranger", nil)
	local byUserId = { [admin.UserId] = admin, [rin.UserId] = rin }
	local function freshProfile()
		return { Cash = 0, Speed = 0, DewberriesCarried = 0, DewberryProgress = 0, Held = {}, MysteryPods = {} }
	end
	local profiles = { [admin] = freshProfile(), [rin] = freshProfile() }
	local world = { mistOn = false, endsAt = nil, mistRefuse = nil, eligibleRefuse = nil, burstMade = 5,
		mossShown = true, filterFails = false, podRoom = 10, bagLoading = false }
	local calls = { start = {}, eligible = 0, bursts = {}, bubbles = {}, filtered = {}, deadlines = {}, gives = 0,
		saves = 0 }
	local said = {}
	local serial = 0
	local stubs = {
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
			UpdateDewberries = function(p, change)
				local profile = profiles[p]
				if not profile then
					return false
				end
				return change(profile) == true
			end,
		},
		EconomyService = { PayReward = function()
			return true
		end },
		TreadmillService = {
			PayReward = function()
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
		PlantService = { ClearGarden = function()
			return 0
		end },
		CarryService = {
			GivePod = function()
				calls.gives += 1
				return true
			end,
			GiveHatched = function()
				return true
			end,
			HeldRoom = function()
				return 30, 0, true
			end,
			IsHeldRestored = function()
				return not world.bagLoading
			end,
			PodRoom = function()
				return world.podRoom, GameConfig.Save.MaxPods - world.podRoom, true
			end,
			SetPodDeadline = function(p, item, at)
				table.insert(calls.deadlines, { player = p, item = item, at = at })
				for _, row in ipairs(profiles[p].Held) do
					if row.Item == item then
						row.HatchAt = at
					end
				end
				return true
			end,
			SyncHeldNow = function() end,
			ForfeitCarry = function() end,
			RefreshWalkSpeed = function() end,
		},
		CombatService = { ClearTrap = function() end },
		WeaponShopService = { RefreshTools = function() end },
		WorldCycleService = {
			StartNight = function()
				return true
			end,
			StartDay = function()
				return true
			end,
		},
		AnnouncementService = { Send = function()
			return true, "Sent.", "a1"
		end },
		WeatherService = {
			State = function()
				return nil
			end,
		},
		MiniEventService = {},
		EnchantedMistService = {
			Hooks = { now = function()
				return 1000
			end },
			AdminStart = function(now, by, seconds)
				table.insert(calls.start, { seconds = seconds, by = by })
				if world.mistRefuse then
					return false, world.mistRefuse
				end
				world.mistOn = true
				world.endsAt = now + (seconds or EnchantedMistData.Schedule.ActiveSeconds)
				return true, "STARTED"
			end,
			AdminEnd = function()
				if not world.mistOn then
					return false, "NOT_ACTIVE"
				end
				world.mistOn = false
				return true, "ENDED"
			end,
			EndsAt = function()
				return world.endsAt
			end,
			IsActive = function()
				return world.mistOn
			end,
			MakeEligible = function()
				if world.eligibleRefuse then
					return false, world.eligibleRefuse
				end
				calls.eligible += 1
				return true, "ELIGIBLE"
			end,
		},
		EnchantedMistBerryService = {
			Hooks = { now = function()
				return 5000
			end },
			Burst = function(at, n, now, near)
				table.insert(calls.bursts, { at = at, n = n, now = now, near = near })
				return world.burstMade
			end,
			Stats = function()
				return { onMap = 3, spawned = 9, picked = 4 }
			end,
		},
		MosskeeperService = { Say = function(text)
			table.insert(calls.bubbles, text)
			return world.mossShown
		end },
		-- SUMMON A SECRET (2026-10-16) reaches the nests; nothing here summons.
		NestService = { SummonSecret = function()
			return false, "NO_SECRET", nil, nil
		end },
	}
	local outerRequire = require
	local function standInRequire(target)
		if type(target) == "table" and target.__standIn ~= nil then
			return target.__standIn
		end
		return outerRequire(target)
	end
	local function siblingParent(map)
		local parent = {}
		function parent:WaitForChild(name)
			local sibling = map[name]
			assert(sibling ~= nil, "asked for an unexpected sibling " .. name)
			return { __standIn = sibling }
		end
		return parent
	end
	-- A copy of the REAL MysteryPodService, its siblings stand-ins, its hooks ours.
	local podSource = Server:WaitForChild("MysteryPodService")
	local podChunk = assert(loadstring(podSource.Source, "=MysteryPodService"))
	setfenv(podChunk, setmetatable({ script = { Name = "MysteryPodService", Parent = siblingParent(stubs) },
		require = standInRequire }, { __index = getfenv(1) }))
	local Pod = podChunk()
	local rolls = Random.new(12)
	Pod.Hooks.now = function()
		return NOW
	end
	Pod.Hooks.random = function()
		return rolls:NextNumber()
	end
	Pod.Hooks.profile = function(p)
		return profiles[p]
	end
	Pod.Hooks.giveShell = function(p, shellId)
		serial += 1
		local item = "spec-shell-" .. serial
		table.insert(profiles[p].Held, { Id = shellId, Item = item, Tier = 1, HatchAt = NOW + EnchantedMistData.HatchSeconds })
		return true, item
	end
	Pod.Hooks.saveSoon = function()
		calls.saves += 1
	end
	stubs.MysteryPodService = Pod

	local module = Server:WaitForChild("AdminService")
	local chunk = assert(loadstring(module.Source, "=AdminService"))
	local scriptStandIn = { Name = "AdminService", Parent = siblingParent(stubs) }
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
	setfenv(chunk, setmetatable({ game = fakeGame, script = scriptStandIn, require = standInRequire },
		{ __index = getfenv(1) }))
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
	Admin.FilterBroadcast = function(text, userId)
		table.insert(calls.filtered, { text = text, userId = userId })
		if world.filterFails then
			return false, nil
		end
		return true, "~" .. text
	end
	local function act(sender, ...)
		table.clear(said)
		return Admin.Handle(sender, ...)
	end
	local function one(line, key)
		return #said == 1 and said[1].title == line and (key == nil or said[1].key == key)
	end
	local function lastAudit()
		local list = Admin.Audit()
		return list[#list]
	end

	-- OFF THE ALLOWLIST: nothing at all.
	local r1 = act(stranger, "MistBerries", rin.UserId, 5)
	local r2 = act(stranger, "Mist", "burst")
	local r3 = act(stranger, "MistPod", rin.UserId, "random", rin.Name)
	check(not r1.ok and not r2.ok and not r3.ok and #said == 0 and profiles[rin].DewberriesCarried == 0
			and #calls.bursts == 0 and next(profiles[rin].MysteryPods) == nil,
		"somebody off the allowlist: every Mist tool refused, nothing changed, nothing said")
	-- A BAD TARGET.
	local gone = act(admin, "MistBerries", 90000000099, 5)
	local nobody = act(admin, "MistReady", nil)
	check(not gone.ok and has(gone.message, "no longer in this server") and not nobody.ok and #said == 0,
		"a target not in this server, or none: refused, nothing said", gone.message)

	-- START MIST NOW's length.
	local r = act(admin, "Mist", "start", 600)
	check(r.ok and calls.start[1] and calls.start[1].seconds == 600 and one("Nicky started the Enchanted Mist!")
			and has(lastAudit().action, "Mist:start:600"),
		"START MIST NOW for 10 minutes: the length reaches the Mist, recorded and said", r.message)
	act(admin, "Mist", "end")
	local before = #calls.start
	r = act(admin, "Mist", "start", 250)
	check(not r.ok and #calls.start == before and #said == 0 and has(r.message, "2, 5 or 10 minutes"),
		"a length that is not 2, 5 or 10 minutes: refused before the Mist is asked, nothing said", r.message)
	r = act(admin, "Mist", "start", nil)
	check(r.ok and calls.start[#calls.start].seconds == nil, "no length: the Mist's own 5 minutes")
	act(admin, "Mist", "end")

	-- MAKE ELIGIBLE NOW.
	r = act(admin, "Mist", "eligible")
	check(r.ok and calls.eligible == 1 and one("Nicky made the Enchanted Mist eligible!")
			and lastAudit().action == "Mist:eligible",
		"MAKE ELIGIBLE NOW: done, recorded, said", r.message)
	world.eligibleRefuse = "OFF"
	r = act(admin, "Mist", "eligible")
	world.eligibleRefuse = nil
	check(not r.ok and has(r.message, "schedule is off") and #said == 0,
		"with the schedule off: refused (the console greys it out), nothing said", r.message)

	-- A BERRY BURST.
	world.mistOn = false
	r = act(admin, "Mist", "burst")
	check(not r.ok and #calls.bursts == 0 and #said == 0 and has(r.message, "needs one"),
		"a burst with no Mist running: refused, no berry, nothing said", r.message)
	world.mistOn = true
	r = act(admin, "Mist", "burst")
	local b = calls.bursts[1]
	check(r.ok and b and b.at == ADMIN_AT and b.n == EnchantedMistData.Spawn.Burst.Count and b.near == "Nicky"
			and b.now == 5000 and one("Nicky dropped a Dewberry burst!") and has(lastAudit().action, "Mist:burst:5"),
		"in a running Mist: five berries asked for around the admin's own body, on the berries' clock, said",
		r.message)
	world.burstMade = 0
	r = act(admin, "Mist", "burst")
	world.burstMade = 5
	check(not r.ok and #said == 0 and has(r.message, "No free floor"), "no floor free: refused, nothing said", r.message)
	local bodyless = admin.Character
	admin.Character = nil
	r = act(admin, "Mist", "burst")
	admin.Character = bodyless
	check(not r.ok and has(r.message, "Stand in the world"), "no body to stand round: refused", r.message)

	-- MOSSKEEPER SAYS.
	r = act(admin, "Mist", "say", "  Welcome   to the\nMist!  ")
	check(r.ok and calls.filtered[1] and calls.filtered[1].text == "Welcome to the Mist!"
			and calls.filtered[1].userId == ADMIN_A and calls.bubbles[1] == "~Welcome to the Mist!" and #said == 0
			and lastAudit().action == "Mist:say",
		"MOSSKEEPER SAYS: its whitespace folded, the broadcast filter's words in his bubble for everybody -- the "
			.. "bubble its own announcement, no notice line", calls.bubbles[1])
	local most = EnchantedMistConfig.Mosskeeper.Talk.SayMaxChars
	local filteredBefore = #calls.filtered
	local tooLong = act(admin, "Mist", "say", string.rep("a", most + 1))
	local fits = act(admin, "Mist", "say", string.rep("b", most))
	local empty = act(admin, "Mist", "say", "   ")
	local notText = act(admin, "Mist", "say", 5)
	check(most == 90 and not tooLong.ok and fits.ok and not empty.ok and not notText.ok
			and #calls.filtered == filteredBefore + 1,
		"at most 90 characters (one more refused before the filter is asked); nothing, or not words: refused",
		tooLong.message)
	world.filterFails = true
	local bubbles = #calls.bubbles
	r = act(admin, "Mist", "say", "Hello")
	world.filterFails = false
	check(not r.ok and #calls.bubbles == bubbles and has(r.message, "filter"),
		"words the filter could not check are never said", r.message)
	world.mossShown = false
	r = act(admin, "Mist", "say", "Hello")
	world.mossShown = true
	check(not r.ok and has(r.message, "not out"), "the Mosskeeper not out: refused", r.message)

	-- A PLAYER'S DEWBERRIES.
	r = act(admin, "MistBerries", rin.UserId, 5)
	check(r.ok and profiles[rin].DewberriesCarried == 5
			and one("Nicky gave Rin 5 Dewberries!", "admin:" .. ADMIN_A .. ":dewberries:" .. rin.UserId)
			and lastAudit().action == "MistBerries" and lastAudit().amount == 5,
		"DEWBERRIES 0 -> 5: set, recorded, said to everybody", r.message)
	r = act(admin, "MistBerries", rin.UserId, 2)
	check(r.ok and profiles[rin].DewberriesCarried == 2 and #said == 0,
		"5 -> 2, a lowering: set, and silent (the owner)", r.message)
	r = act(admin, "MistBerries", rin.UserId, 4)
	check(r.ok and one("Nicky gave Rin 2 Dewberries!"), "2 -> 4, a raise: says what was given, 2",
		said[1] and said[1].title)
	r = act(admin, "MistBerries", rin.UserId, 4)
	check(not r.ok and has(r.message, "already") and #said == 0, "the same count again: refused, nothing said", r.message)
	local outOfRange = {}
	for _, bad in ipairs({ CAP + 1, -1, 2.5, "3", 0 / 0 }) do
		local reply = act(admin, "MistBerries", rin.UserId, bad)
		if reply.ok or #said > 0 then
			table.insert(outOfRange, tostring(bad))
		end
	end
	check(#outOfRange == 0 and profiles[rin].DewberriesCarried == 4,
		string.format("a count outside 0..%d, or not a whole number: refused, nothing changed", CAP),
		table.concat(outOfRange, ", "))
	r = act(admin, "MistBerries", admin.UserId, 1)
	check(r.ok and #said == 0, "to oneself: set, and said to nobody (the owner, 2026-10-13)", said[1] and said[1].title)

	-- A PLAYER'S PROGRESS.
	r = act(admin, "MistProgress", rin.UserId, 7)
	check(r.ok and profiles[rin].DewberryProgress == 7 and one(string.format("Nicky set Rin's Dewberry progress to 7/%d", PER)),
		"PROGRESS 0 -> 7: set and said", r.message)
	r = act(admin, "MistProgress", rin.UserId, 0)
	check(r.ok and profiles[rin].DewberryProgress == 0 and #said == 0 and lastAudit().action == "MistProgress",
		"a reset to 0: set and recorded, and silent (the owner)", r.message)
	local badProgress = act(admin, "MistProgress", rin.UserId, PER)
	check(not badProgress.ok and #said == 0 and profiles[rin].DewberryProgress == 0,
		string.format("%d or more: refused (%d earns a pod)", PER, PER), badProgress.message)
	r = act(admin, "MistProgress", admin.UserId, 3)
	check(r.ok and #said == 0, "to oneself: set, and said to nobody (the owner, 2026-10-13)",
		said[1] and said[1].title)

	-- A MYSTERIOUS POD.
	r = act(admin, "MistPod", rin.UserId, "random", nil)
	check(not r.ok and has(r.message, "username") and next(profiles[rin].MysteryPods) == nil and #said == 0,
		"a pod for somebody else without their username: refused, nothing given", r.message)
	r = act(admin, "MistPod", rin.UserId, "random", rin.Name)
	local items = {}
	for item in pairs(profiles[rin].MysteryPods) do
		table.insert(items, item)
	end
	local rec = profiles[rin].MysteryPods[items[1]]
	check(r.ok and #items == 1 and rec and rec.ReadyAt == NOW + EnchantedMistData.HatchSeconds
			and rec.PoolVersion == EnchantedMistData.Pool.Version and #profiles[rin].Held == 1
			and one("Nicky gave Rin a Mysterious Pod!", "admin:" .. ADMIN_A .. ":mistpod:" .. rin.UserId)
			and calls.saves >= 1,
		"RANDOM, confirmed: stage 4's own grant -- the shell in the Bag, the hidden record ready in 30 s -- saved soon, said",
		r.message)
	check(namesCreature(r.message) == nil and namesCreature(said[1] and said[1].title) == nil
			and has(lastAudit().action, "MistPod:random:" .. tostring(rec and rec.Species)),
		"neither the line nor the admin's answer names what is inside; the server log does", lastAudit().action)
	r = act(admin, "MistPod", admin.UserId, { species = "elderbough", size = 7 }, nil)
	local mine = nil
	for _, record in pairs(profiles[admin].MysteryPods) do
		mine = record
	end
	check(r.ok and mine and mine.Species == "elderbough" and mine.Size == 7 and #said == 0,
		"a chosen creature and size, to oneself (no username needed): saved as chosen, said to nobody", mine and mine.Species)
	r = act(admin, "MistPod", admin.UserId, { species = "snarlbloom" }, nil)
	local secret = false
	for _, record in pairs(profiles[admin].MysteryPods) do
		if record.Species == "snarlbloom" and record.Size == nil then
			secret = true
		end
	end
	check(r.ok and secret, "a Secret, chosen: no size, its own (saved without one)")
	local held = #profiles[admin].Held
	local refusals = {}
	for _, case in ipairs({
		{ { species = "snarlbloom", size = 3 }, "keeps its own size" },
		{ { species = "petalpip" }, "not in the Mysterious Pod" },
		{ { species = "elderbough", size = 9 }, "Tiny to Colossal" },
		{ { species = "elderbough", size = 2.5 }, "Tiny to Colossal" },
		{ { species = "elderbough", size = 3, extra = true }, "RANDOM or a sprout" },
		{ "surprise", "RANDOM or a sprout" },
	}) do
		local reply = act(admin, "MistPod", admin.UserId, case[1], nil)
		if reply.ok or #said > 0 or not has(reply.message, case[2]) then
			table.insert(refusals, case[2] .. " <- " .. tostring(reply.message))
		end
	end
	check(#refusals == 0 and #profiles[admin].Held == held,
		"refused, nothing given: a size for a Secret, a creature not in the pod, a size out of range, a stray field, "
			.. "anything but RANDOM or a choice", table.concat(refusals, "; "))
	world.podRoom = 0
	r = act(admin, "MistPod", rin.UserId, "random", rin.Name)
	world.podRoom = 10
	check(not r.ok and has(r.message, "No room") and #said == 0 and #profiles[rin].Held == 1,
		"A FULL BAG: refused, nothing given, nothing said", r.message)
	world.bagLoading = true
	r = act(admin, "MistPod", rin.UserId, "random", rin.Name)
	world.bagLoading = false
	check(not r.ok and has(r.message, "has not loaded") and #profiles[rin].Held == 1, "a Bag still loading: refused",
		r.message)

	-- MAKE READY NOW.
	local rinItem = items[1]
	r = act(admin, "MistReady", rin.UserId)
	local readyRec = profiles[rin].MysteryPods[rinItem]
	local moved = false
	for _, d in ipairs(calls.deadlines) do
		if d.player == rin and d.item == rinItem and d.at == NOW then
			moved = true
		end
	end
	check(r.ok and readyRec.ReadyAt == NOW and moved and profiles[rin].Held[1].HatchAt == NOW
			and one("Nicky made Rin's Mysterious Pods ready!") and lastAudit().action == "MistReady"
			and lastAudit().amount == 1,
		"READY NOW: the hidden record's time and the Bag row's own both now, recorded, said", r.message)
	r = act(admin, "MistReady", rin.UserId)
	check(not r.ok and has(r.message, "no Mysterious Pod waiting") and #said == 0,
		"again: nothing waits -- refused, nothing said", r.message)

	-- SPAWN NEVER MAKES WHAT SPAWNCATALOG DOES NOT LIST: the raw shell.
	local gives = calls.gives
	r = act(admin, "Spawn", admin.UserId, { species = "mysterypod", form = "pod", size = 1, quantity = 1,
		request = "spec-mist-shell-01" }, nil)
	check(not r.ok and has(r.message, "cannot be spawned") and calls.gives == gives and #said == 0,
		"SPAWN refuses the Mysterious Pod's raw shell (it would sit with no outcome): its door is GIVE A MYSTERIOUS POD",
		r.message)

	--==========================================================================
	say("\n-- 3. the services' own parts --")
	--==========================================================================
	-- ENCHANTEDMISTSERVICE: a copy on a fake clock, its config a copy.
	local mistSource = Server:WaitForChild("EnchantedMistService")
	local configCopy = table.clone(EnchantedMistConfig)
	local mistChunk = assert(loadstring(mistSource.Source, "=EnchantedMistService"))
	setfenv(mistChunk, setmetatable({ script = mistSource, require = function(target)
		if target.Name == "WorldCycleService" then
			return { OnDawn = function()
				return function() end
			end }
		elseif target.Name == "EnchantedMistConfig" then
			return configCopy
		end
		return require(target)
	end }, { __index = getfenv(1) }))
	local Mist = mistChunk()
	Mist.Hooks.publish = function() end
	Mist.Hooks.random = function()
		return 1800
	end
	Mist.Hooks.isNight = function()
		return false
	end
	configCopy.Enabled = false
	Mist._boot(0)
	local offOk, offWhy = Mist.MakeEligible(10, "spec")
	local startOk = Mist.AdminStart(10, "spec", 120)
	check(not offOk and offWhy == "OFF" and startOk and Mist.EndsAt() == 130,
		"schedule off: MAKE ELIGIBLE NOW refused (OFF); an admin's 2-minute Mist still starts and ends 120 s on")
	Mist.AdminEnd(20, "spec")
	local badOk, badWhy = Mist.AdminStart(30, "spec", 250)
	check(not badOk and badWhy == "BAD_LENGTH" and not Mist.IsActive(), "any other length: refused (BAD_LENGTH)")
	configCopy.Enabled = true
	Mist.MissingBindings = function()
		return {}
	end
	Mist._boot(0)
	local coolOk, coolWhy = Mist.MakeEligible(100, "spec")
	check(Mist.State() == STATES.Eligible and coolOk and coolWhy == "ELIGIBLE" and Mist.EligibleAt() == 100,
		"schedule on, cooling down: MAKE ELIGIBLE NOW makes it eligible at once (it starts nothing itself)")
	local againOk, againWhy = Mist.MakeEligible(110, "spec")
	check(not againOk and againWhy == "ALREADY_ELIGIBLE", "already eligible: nothing to cut")
	Mist.AdminStart(200, "spec", 600)
	local activeOk, activeWhy = Mist.MakeEligible(210, "spec")
	check(Mist.EndsAt() == 800 and not activeOk and activeWhy == "ACTIVE",
		"an admin's 10-minute Mist ends 600 s on; MAKE ELIGIBLE NOW refused while one runs")
	Mist.AdminEnd(300, "spec")

	-- THE BERRIES' BURST: a copy, its siblings stand-ins, on a fake floor.
	local berrySource = Server:WaitForChild("EnchantedMistBerryService")
	local berryChunk = assert(loadstring(berrySource.Source, "=EnchantedMistBerryService"))
	local berryStubs = {
		PlayerDataService = stubs.PlayerDataService,
		MiniEventService = {},
		EnchantedMistService = { EventId = function()
			return "spec-mist-1"
		end, OnStart = function()
			return function() end
		end, OnEnd = function()
			return function() end
		end },
	}
	setfenv(berryChunk, setmetatable({ script = { Name = "EnchantedMistBerryService", Parent = siblingParent(berryStubs) },
		require = standInRequire }, { __index = getfenv(1) }))
	local Berries = berryChunk()
	local berryFolder = Instance.new("Folder")
	berryFolder.Name = "Berries"
	berryFolder.Parent = fixture
	local berryRolls = Random.new(3)
	local floorY = 0
	Berries.Hooks.random = function()
		return berryRolls:NextNumber()
	end
	Berries.Hooks.eventId = function()
		return "spec-mist-1"
	end
	Berries.Hooks.players = function()
		return {}
	end
	Berries.Hooks.parent = function()
		return berryFolder
	end
	Berries.Hooks.sound = function() end
	Berries.Hooks.spot = function()
		return nil, nil
	end
	Berries.Hooks.floor = function(x, z)
		if math.abs(x) > 400 or math.abs(z) > 400 then
			return nil
		end
		return Vector3.new(x, floorY, z)
	end
	check(Berries.Burst(Vector3.new(0, 3, 0), 5, 10, "Nicky") == 0, "no Mist running: a burst puts nothing down")
	Berries._begin({ eventId = "spec-mist-1", endsAt = 1e9 }, 0)
	local made = Berries.Burst(Vector3.new(0, 3, 0), 5, 10, "Nicky")
	local list = Berries.List()
	local spaced, nearby, onFloor = true, true, true
	local S = EnchantedMistData.Spawn
	for i, a in ipairs(list) do
		local flat = Vector3.new(a.at.X, 0, a.at.Z)
		if flat.Magnitude > S.Burst.MaxRadius + 0.01 or flat.Magnitude < S.Burst.MinRadius - 0.01 then
			nearby = false
		end
		if math.abs(a.at.Y - floorY) > 1e-6 then
			onFloor = false
		end
		for j = i + 1, #list do
			local other = list[j]
			if (Vector3.new(a.at.X, 0, a.at.Z) - Vector3.new(other.at.X, 0, other.at.Z)).Magnitude < S.Spacing then
				spaced = false
			end
		end
	end
	check(made == 5 and #list == 5 and spaced and nearby and onFloor and has(list[1].where, "Nicky"),
		string.format("in a running Mist: five berries around the admin, %d..%d studs out, on the floor, %d apart -- "
			.. "the natural berries' spacing kept", S.Burst.MinRadius, S.Burst.MaxRadius, S.Spacing), made)
	local second = Berries.Burst(Vector3.new(120, 3, 0), 5, 11, "Nicky")
	local natural = Berries._spawn(12)
	local stats = Berries.Stats()
	check(second == 5 and stats.onMap == 10 and stats.onMap > S.MaxActive and natural == nil and stats.spawned == 10
			and stats.picked == 0 and stats.eventId == "spec-mist-1",
		string.format("two bursts pass MaxActive (%d on the map, cap %d); the natural spawner then waits; the stats "
			.. "count every one", stats.onMap, S.MaxActive))
	Berries.Hooks.floor = function(x, z)
		return Vector3.new(x, if math.abs(x) < 1 and math.abs(z + 300) < 1 then 0 else 9, z)
	end
	check(Berries.Burst(Vector3.new(0, 3, -300), 5, 13, "Nicky") == 0,
		"no floor at the admin's own height nearby: nothing put down, nothing forced")
	Berries._stop("spec")

	-- THE MOSSKEEPER'S LINE: the real module, through its hooks.
	local Mosskeeper = require(Server:WaitForChild("MosskeeperService"))
	local mossHooks = table.clone(Mosskeeper.Hooks)
	table.insert(restores, function()
		for k, v in pairs(mossHooks) do
			Mosskeeper.Hooks[k] = v
		end
	end)
	local Talk = require(Shared:WaitForChild("MosskeeperTalk"))
	local TALK = EnchantedMistConfig.Mosskeeper.Talk
	local HttpService = game:GetService("HttpService")
	local heard = {}
	Mosskeeper.Hooks.publish = function(value)
		table.insert(heard, value)
	end
	Mosskeeper.Hooks.serverNow = function()
		return 5000
	end
	Mosskeeper.Hooks.shown = function()
		return true
	end
	local sayOk = Mosskeeper.Say("Hi there")
	local line = heard[1] and HttpService:JSONDecode(heard[1])
	check(sayOk and #heard == 1 and type(line) == "table" and line.t == "Hi there" and type(line.n) == "number"
			and line.e == 5000 + Talk.sayTime("Hi there"),
		"his line goes up once, on the Workspace for everybody: its count, its words, and the server time it ends",
		heard[1])
	Mosskeeper.Say("Hi there")
	local again = heard[2] and HttpService:JSONDecode(heard[2])
	check(again and line and again.n == line.n + 1 and again.t == "Hi there",
		"the same words said again are a new line (their own count), so they keep their own full time")
	local n, text, left = Talk.saidLeft(line, 5005)
	local gone = Talk.saidLeft(line, 5000 + Talk.sayTime("Hi there") + 0.01)
	local _, _, capped = Talk.saidLeft({ n = 1, t = "Hi there", e = 5000 + 9999 }, 5000)
	check(n == line.n and text == "Hi there" and left == Talk.sayTime("Hi there") - 5 and gone == nil
			and capped == Talk.sayTime("Hi there") and Talk.saidLeft({ n = 1, t = "", e = 6000 }, 5000) == nil
			and Talk.saidLeft("junk", 5000) == nil,
		"a late joiner 5 s in shows the rest (7 s); none once its time is up; never more than its own time; "
			.. "nothing from a malformed line", tostring(left))
	Mosskeeper.Hooks.shown = function()
		return false
	end
	table.clear(heard)
	check(not Mosskeeper.Say("Hi there") and #heard == 0, "not while he is not shown")
	Mosskeeper.Hooks.shown = function()
		return true
	end
	check(not Mosskeeper.Say("") and #heard == 0, "nothing for no words")

	-- THE SKIP (the owner): a click or a tap anywhere, on that screen only, after SaySkipAfter; never a touch
	-- that starts on the move stick, unless it landed on one of the game's buttons there.
	local after = TALK.SaySkipAfter + 0.1
	local UIT, KC = Enum.UserInputType, Enum.KeyCode
	local function press(kind, key, x, y, onButton)
		return { kind = kind, key = key or KC.Unknown, x = x or 0, y = y or 0, onButton = onButton == true }
	end
	local dynamic = { x = 0, y = 240, w = 426, h = 476 }
	local classic = { x = 60, y = 500, w = 120, h = 120 }
	check(TALK.SaySkipAfter == 0.5 and not Talk.skipsSaid(press(UIT.MouseButton1), 0.3, {})
			and Talk.skipsSaid(press(UIT.MouseButton1), after, {}),
		"a click skips it -- but not in its first half second, so a press already on its way never does")
	check(Talk.skipsSaid(press(UIT.MouseButton2), after, {}) and Talk.skipsSaid(press(UIT.MouseButton3), after, {})
			and Talk.skipsSaid(press(UIT.Gamepad1, KC.ButtonA), after, {})
			and Talk.skipsSaid(press(UIT.Gamepad1, KC.ButtonR2), after, {}),
		"any mouse button, and the pad's A or R2, skip it")
	check(not Talk.skipsSaid(press(UIT.Keyboard, KC.Space), after, {})
			and not Talk.skipsSaid(press(UIT.Keyboard, KC.E), after, {})
			and not Talk.skipsSaid(press(UIT.Gamepad1, KC.ButtonB), after, {})
			and not Talk.skipsSaid(press(UIT.MouseMovement), after, {})
			and not Talk.skipsSaid(press(UIT.MouseWheel), after, {}),
		"keys, the pad's other buttons, moving the mouse and its wheel never skip it")
	check(not Talk.skipsSaid(press(UIT.Touch, nil, 100, 600), after, { dynamic })
			and not Talk.skipsSaid(press(UIT.Touch, nil, 100, 560), after, { classic }),
		"a touch that starts on the move stick -- the dynamic stick's whole area, or the classic stick -- never skips "
			.. "it: walking never does")
	check(Talk.skipsSaid(press(UIT.Touch, nil, 900, 600), after, { dynamic })
			and Talk.skipsSaid(press(UIT.Touch, nil, 100, 600, true), after, { dynamic })
			and Talk.skipsSaid(press(UIT.Touch, nil, 100, 100), after, { dynamic })
			and Talk.skipsSaid(press(UIT.Touch, nil, 100, 600), after, {})
			and Talk.skipsSaid(press(UIT.MouseButton1, nil, 100, 600), after, { dynamic })
			and not Talk.skipsSaid(press(UIT.Touch, nil, 900, 600), 0.3, { dynamic }),
		"any other tap skips it -- the screen, the jump, a game button even over the stick's area, a phone with "
			.. "no stick showing; a click is never a walk; a tap in its first half second does not")

	-- MYSTERYPODSERVICE: MakeReady on a profile's records.
	local profile = { MysteryPods = {
		a = { Species = "hollowl", Size = 2, ReadyAt = NOW + 20 },
		b = { Species = "gnarlmaw", ReadyAt = NOW - 5 },
	} }
	local late, all = Pod.MakeReady(profile, NOW)
	check(#late == 1 and late[1] == "a" and #all == 2 and profile.MysteryPods.a.ReadyAt == NOW
			and profile.MysteryPods.b.ReadyAt == NOW - 5,
		"MakeReady: only a pod still waiting moves to now; one already ready keeps its time")
	check(Pod.PoolEntry("elderbough") ~= nil and Pod.PoolEntry("petalpip") == nil and Pod.PoolEntry(nil) == nil,
		"the pool's entries by id: only the pod's own creatures")

	-- THE SOURCES: the console asks; the Mosskeeper's bubble shows a "say".
	local ui = Server.AdminService:FindFirstChild("AdminConsoleUI").Source
	local mossUi = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("MosskeeperUI")
	local mossSrc = mossUi and mossUi.Source or ""
	check(not has(mossSrc, 'payload.phase == "say"')
			and has(mossSrc, "Workspace:GetAttributeChangedSignal(CFG.SaidAttribute):Connect(readSaid)\nreadSaid()")
			and has(mossSrc, "MosskeeperTalk.saidLeft(if ok then line else nil, Workspace:GetServerTimeNow())")
			and has(mossSrc, "said.untilAt = os.clock() + left")
			and has(mossSrc, "if not text or isOpen or os.clock() >= said.untilAt then"),
		"his bubble reads an admin's line off the Workspace -- now and on every change, so a late joiner shows the "
			.. "rest -- for what is left of its time; never over a talk, which shows it after if its time is not up")
	check(has(mossSrc, "if not npcModel() then\n\t\t-- Not streamed in yet: again shortly, while its time lasts.")
			and has(mossSrc, "if said.n == mine and said.shownAt == nil then"),
		"him not streamed in yet (far off, or just joined): the line shows once he is, while its time lasts")
	check(has(mossSrc, "local mine = said.n") and has(mossSrc, "if said.n == mine and not isOpen then")
			and has(mossSrc, "n == said.n then"),
		"each line counts: the same words said again keep their own full time (the first one's timer never hides "
			.. "them), and the same line read twice is shown once")
	local skipAt = string.find(mossSrc, "UserInputService.InputBegan:Connect(function(input: InputObject)\n\tlocal shownAt = said.shownAt", 1, true)
	local skipBody = if skipAt then string.sub(mossSrc, skipAt, (string.find(mossSrc, "\nend)", skipAt, true) or skipAt) + 5) else ""
	check(skipAt ~= nil and has(skipBody, "if not said.text or not shownAt or isOpen or os.clock() >= said.untilAt then")
			and has(skipBody, "MosskeeperTalk.skipsSaid(press, os.clock() - shownAt, if touch then stickRects() else {})")
			and has(skipBody, "hideSaid()") and not has(skipBody, "FireServer") and not has(skipBody, "return Enum")
			and not has(mossSrc, "BindAction(\"SeedMosskeeperSkip")
			and has(mossSrc, 'local STICKS = { "DynamicThumbstickFrame", "ThumbstickFrame" }')
			and has(mossSrc, "if frame and frame:IsA(\"GuiObject\") and frame.Visible then")
			and has(mossSrc, "object:IsA(\"GuiButton\") and object.Active and not (touchGui and object:IsDescendantOf(touchGui))"),
		"the skip: heard on UserInputService, never bound or sunk (the press still does its job); only while his "
			.. "admin line shows, never a talk's; on this screen only (nothing sent); the stick's live area, whichever "
			.. "shows, and the game's own buttons over it")
	check(has(mossSrc, "local function hideSaid()\n\tsaid.text = nil\n\tsaid.shownAt = nil\n\tsetHis(nil)\nend"),
		"a skip is for good: the line's words are dropped, so a talk's close never brings it back")
	local longest = string.rep("a", TALK.SayMaxChars)
	local slow = string.rep("a", math.ceil((TALK.SaySeconds - TALK.ReadHold) / TALK.ReadPerChar) + 50)
	check(TALK.SaySeconds == 12 and Talk.sayTime("Hi!") == TALK.SaySeconds and Talk.sayTime(longest) == TALK.SaySeconds
			and Talk.sayTime(slow) == Talk.readTime(slow) and Talk.readTime(slow) > TALK.SaySeconds,
		"an admin's line stays 12 s, as long as an admin announcement -- even the longest he may say -- or its reading "
			.. "time if that were longer", string.format("%.2f %.2f %.2f", Talk.sayTime("Hi!"), Talk.sayTime(longest), Talk.sayTime(slow)))
	local adminSrc = Server:WaitForChild("AdminService").Source
	check(has(adminSrc, "local ok, stats = pcall(EnchantedMistBerryService.Stats)")
			and has(adminSrc, "for name, value in pairs({ MistOnMap = stats.onMap, MistSpawned = stats.spawned,")
			and has(adminSrc, "MistPicked = stats.picked }) do") and has(ui, 'local onMap = screen:GetAttribute("MistOnMap")')
			and has(ui, 'tonumber(screen:GetAttribute("MistSpawned"))') and has(ui, 'tonumber(screen:GetAttribute("MistPicked"))'),
		"MIST STATUS: the server puts the running Mist's berries on each admin's console once a second -- on the map, "
			.. "appeared, picked -- and the console shows them; nobody else is told")
	check(has(ui, 'ui.sayAsk.words.Text = "Say this as the Mosskeeper to everyone here?"')
			and has(ui, 'setAsking("say", nil)') and has(ui, 'task.spawn(send, Model.args.mist("eligible"))')
			and has(ui, 'ui.mistEligible.style(if not scheduleOn then "off"'),
		"the console asks before the Mosskeeper speaks, and greys MAKE ELIGIBLE NOW out while the schedule is off")
end)

for _, restore in ipairs(restores) do
	pcall(restore)
end
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
fixture:Destroy()
say(string.format("\nAdminMistSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
