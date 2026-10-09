--!strict
-- Steal a Seed :: AdminService
--
-- A small developer console for three accounts: add cash, add Speed, and reset a
-- player's saved progress to a fresh account, on anybody in this server; and
-- start the night or the day for the whole server; announce; (2026-10-07,
-- SPAWN, which replaced 2026-10-02's SECRET ITEMS) give any plant or pod the
-- game has to anybody in this server; the weather for this server (every
-- admin account since 2026-10-07); and (2026-10-03, MINI EVENTS) start or end
-- a Ticket Disco for this server.
-- Nothing else, and nobody else.
--
--==============================================================================
-- WHY THIS IS NOT DebugService
--
-- DebugService is Studio-only on purpose: the beta's debug panel and its remote
-- were removed on 2026-09-21 (727ebcb), and DebugReleaseSpec keeps them removed.
-- This is the other shape -- a few actions, live on published servers, for three
-- named accounts -- so it is a service of its own with one narrow door, and
-- DebugService stays exactly as it is. Nothing here is configured from
-- GameConfig, which every client can read: the allowlist and the limits live in
-- this file, on the server.
--
--==============================================================================
-- WHO: THREE USER IDS, AND NOTHING THAT CAN BE FAKED
--
-- Resolved 2026-09-23 through Roblox's users API in both directions -- name to
-- id (POST users.roblox.com/v1/usernames/users) and id back to name
-- (GET users.roblox.com/v1/users/<id>), both exact -- and nicnicniccoal's again
-- by the engine in Studio Play. The third, TappedYou (the owner's, 2026-10-07),
-- was resolved the same two ways that day: the name to 1139904972, and
-- 1139904972 back to "TappedYou". The UserId is what the engine stamps on every
-- request; a username can change and a display name is anybody's. Nothing here
-- reads a name, a display name, a group rank or an attribute to decide who may
-- ask. An id that could not be verified would not be in this list: the list is
-- the whole door, and it is shut to everybody it does not name.
--
--==============================================================================
-- NOTHING SHIPS TO ANYBODY ELSE
--
-- The console's client, AdminConsoleUI, is a LocalScript child of THIS module,
-- in ServerScriptService, which never replicates. For an allowlisted player
-- this builds a ScreenGui in their own PlayerGui -- which only their client
-- ever receives -- holding a copy of that script and the RemoteFunction it asks
-- through. Everybody else gets no button, no panel, no remote and no source.
-- The remote not existing for them is the first wall; Handle is the second, and
-- it refuses a forged call from anybody the list does not name.
--
--==============================================================================
-- EVERY REQUEST, CHECKED IN THIS ORDER, BEFORE ANYTHING CHANGES
--
--   1. the sender is one of the three UserIds
--   2. one request a second per admin, whatever it is -- except Announce
--      (2026-10-03): consecutive announcements go without waiting, under
--      AnnouncementService's own safeguards (a resend is not sent twice, a
--      flood is capped, the queue is bounded). An announcement still counts
--      as this admin's last request, so every other action's limit is as it was
--   3. the action is one of ACTIONS (Spawn has its own checks after this, in
--      spawn: the request's shape, a species and a size SeedData really has,
--      the target and -- for anybody but the sender -- their username, a
--      remembered answer, a cooldown, the bag's room for the whole quantity)
--   4. Start Night and Start Day go to WorldCycleService from here: they act
--      on the whole server and name nobody; Announce goes to
--      AnnouncementService.Send (2026-10-01), which checks its own words;
--      Weather goes to WeatherService and MiniEvent (2026-10-03) to
--      MiniEventService, each for any allowlisted account (the weather was
--      the owner's alone until 2026-10-07), with its verb and whole-seconds
--      duration checked here
--   5. otherwise the target is a UserId of a player in THIS server, now
--   6. the target's profile has loaded
--   7. for cash and Speed, a finite whole number from 1 to the limit -- the
--      save's own (2026-10-07: GameConfig.Save.MaxCash and MaxSpeedScore); for
--      a reset, the target's username typed back, and a profile that is saving
--
-- Cash and Speed go through the faucets' own one-off payers,
-- EconomyService.PayReward and TreadmillService.PayReward -- the ones the Biome
-- Harvest and the Robux Speed packs use -- so the save cap, the dirty flag, the
-- stats, the leaderboard columns, the Speed tier and WalkSpeed all move exactly
-- as they do for every other coin. What was actually added is read back off
-- the profile, so a grant the cap cut short says so.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Notice = require(Shared:WaitForChild("Notice"))
-- What SPAWN can make (2026-10-07): the console draws its choices from the same module.
local SpawnCatalog = require(script:WaitForChild("SpawnCatalog"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlantService = require(script.Parent:WaitForChild("PlantService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local WeaponShopService = require(script.Parent:WaitForChild("WeaponShopService"))
local WorldCycleService = require(script.Parent:WaitForChild("WorldCycleService"))
local AnnouncementService = require(script.Parent:WaitForChild("AnnouncementService"))
local WeatherService = require(script.Parent:WaitForChild("WeatherService"))
local MiniEventService = require(script.Parent:WaitForChild("MiniEventService"))

local SAVE = GameConfig.Save

local AdminService = {}
-- After the profiles, the two faucets and everything a reset rebuilds.
AdminService.Priority = 95

--==============================================================================
-- THE ALLOWLIST: VERIFIED NUMERIC USER IDS ONLY
--==============================================================================
local ALLOWED: { [number]: string } = {
	[11607308004] = "Teambarnze825",
	[4119740186] = "nicnicniccoal",
	-- 2026-10-07, the owner's: every power Teambarnze825 has, and nothing of
	-- the owner's (IsOwner). No ADMIN title either (HasTitle: the owner and
	-- Teambarnze825, since 2026-10-09).
	[1139904972] = "TappedYou",
}

--==============================================================================
-- THE LIMITS
--
-- Per request. UP TO THE SAVE LIMITS THEMSELVES (2026-10-07, the owner's: one
-- Money or Speed request may add up to the save limit), READ from
-- GameConfig.Save rather than copied, so the two can never drift apart; the
-- save limits are not this file's to change. 1e15 is under 2^53, so every
-- whole number up to it is exact. Exposed so AdminSpec can shorten the
-- interval; nothing a client sends can reach it.
--==============================================================================
AdminService.Config = {
	MinInterval = 1,
	MaxMoney = SAVE.MaxCash,
	MaxSpeed = SAVE.MaxSpeedScore,
	--==========================================================================
	-- SPAWN (2026-10-07; it replaced SECRET ITEMS' SecretGrants of 2026-10-02):
	-- the owner approved every allowlisted account giving any plant or pod to
	-- anybody in the server, on live servers and in Studio. ITS OWN SWITCH, on
	-- the server: natural Secret spawning has its own (GameConfig.Secret.Enabled,
	-- on since 2026-10-09), and no spawn reads that one -- only the Ready line
	-- names it.
	--==========================================================================
	Spawning = true,
	-- Between two spawns by one admin, on top of MinInterval. Every spawn ends
	-- in a save, and a DataStore key takes one write in six seconds.
	SpawnCooldown = 6,
	-- How long a request's answer is remembered, so the same request sent twice
	-- -- a double press, a resend -- is answered again and never given twice.
	SpawnAnswerSeconds = 300,
}

local GUI_NAME = "SeedAdmin"
local REMOTE_NAME = "AdminRequest"
local TEMPLATE_NAME = "AdminConsoleUI"
local CONSOLE_MODULES = { "SpawnCatalog", "ConsoleModel" }
local AUDIT_KEEP = 50

local ACTIONS: { [string]: boolean } = {
	AddMoney = true,
	AddSpeed = true,
	ResetPlayerProgress = true,
	StartNight = true,
	StartDay = true,
	-- 2026-10-01: an announcement, to this server or every server. The checks
	-- past this file's -- the words, the safeguards, the filter -- are
	-- AnnouncementService.Send's; it is reached from nowhere but here.
	Announce = true,
	-- 2026-10-07: any plant or pod into anybody's bag in this server (SPAWN;
	-- it replaced 2026-10-02's GrantSecret).
	Spawn = true,
	-- 2026-10-02: the Rain event, for THIS server (WeatherService), by ANY
	-- allowlisted account since 2026-10-07 (the owner's alone before). The
	-- second word is "start" (rain), "thunder" (a Thunderstorm) or "end", the
	-- third the duration in seconds.
	Weather = true,
	-- 2026-10-03: a GLOBAL mini event (Ticket Disco) for every server of this
	-- place, by ANY allowlisted account (MiniEventService). The second word
	-- is the mode -- "ticketdisco", "disco" (DISCO + MILL), "party" (the pure
	-- DISCO ONLY, 2026-10-04), "tickets" or "podrush" (POD RUSH, 2026-10-09)
	-- -- or "end"; the third the duration.
	MiniEvent = true,
}

-- The mini event's verbs: each start verb names its mode, and "end".
local MINI_STARTS: { [string]: boolean } = {
	ticketdisco = true,
	disco = true,
	party = true,
	tickets = true,
	podrush = true,
}

-- A spawn request is exactly these five fields: the species id, "pod" or
-- "plant", the size (a tier index), how many, and the request's own id.
local SPAWN_FIELDS: { [string]: boolean } = {
	species = true,
	form = true,
	size = true,
	quantity = true,
	request = true,
}
-- The two that act on the whole server rather than on a player: no target.
local WHOLE_SERVER: { [string]: boolean } = {
	StartNight = true,
	StartDay = true,
}

-- `saved` is a spawn's: false when the items were given in this server but the
-- save has not landed yet (the autosave keeps trying); `given` how many. `shown`
-- is an announcement's: whether it was queued in this server at all (false:
-- nothing went anywhere, so the console gives the words back).
export type Reply = {
	ok: boolean,
	message: string,
	added: number?,
	saved: boolean?,
	given: number?,
	shown: boolean?,
}
-- `species`, `size`, `form` and `quantity` are a spawn's (2026-10-07).
export type AuditEntry = {
	at: string,
	admin: number,
	target: number,
	action: string,
	amount: number?,
	asked: number?,
	species: string?,
	size: number?,
	form: string?,
	quantity: number?,
}
export type SpawnItem = { species: string, size: number, form: string, quantity: number }

local lastRequest: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local lastStranger: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local resetting: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any
-- SPAWN: a spawn running per admin, the last accepted spawn's time, and every
-- request id answered lately with its answer (nil while still running).
local spawnBusy: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local lastSpawn: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local spawnAnswers: { [any]: { [string]: { at: number, reply: Reply? } } } =
	setmetatable({}, { __mode = "k" }) :: any
local audit: { AuditEntry } = {}
local serviceConnections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/AdminService] " .. message)
end

-- Read, never trusted: the sender of a real request is a Player the engine
-- stamped, but Handle is also reachable from specs with stand-ins, and a
-- request with no usable id is simply nobody.
local function userIdOf(player: any): number?
	local ok, id = pcall(function()
		return player.UserId
	end)
	if ok and type(id) == "number" and id > 0 and id == math.floor(id) then
		return id
	end
	return nil
end

local function nameOf(player: any): string
	local ok, name = pcall(function()
		return player.Name
	end)
	return if ok and type(name) == "string" then name else "?"
end

-- 1234567 -> "1,234,567". Exact for every whole number the limits allow.
local function commas(n: number): string
	local digits = string.format("%.0f", n)
	local grouped = string.reverse(digits)
	grouped = string.gsub(grouped, "(%d%d%d)", "%1,")
	grouped = string.reverse(grouped)
	return (string.gsub(grouped, "^,", ""))
end
AdminService.commas = commas

function AdminService.IsAdmin(player: any): boolean
	local id = userIdOf(player)
	return id ~= nil and ALLOWED[id] ~= nil
end

--==============================================================================
-- WHICH OF THEM IS THE OWNER (2026-10-01)
--
-- The owner's own account -- the one they play and build in Studio as -- by
-- UserId, and only while it is on the allowlist above. Read by the cosmetic
-- ADMIN title over the head (HasTitle, below) and nothing else: every power
-- is every allowlisted account's alike, the weather too since 2026-10-07 (the
-- owner's, from 2026-10-02 until then).
--==============================================================================
local OWNER_USER_ID = 4119740186

function AdminService.IsOwner(player: any): boolean
	local id = userIdOf(player)
	return id ~= nil and id == OWNER_USER_ID and ALLOWED[id] ~= nil
end

--==============================================================================
-- WHO WEARS THE ADMIN TITLE (2026-10-09, the owner: "add admin title to
-- michael"; "yes, Teambarnze825 is Michael")
--
-- The owner, and the accounts listed here by UserId while they are on the
-- allowlist. The floating ADMIN word over the head (OwnerTitleService) and
-- nothing else: a listed account does not become the owner, and no power
-- changes. TappedYou is not listed.
--==============================================================================
local TITLED: { [number]: string } = {
	[11607308004] = "Teambarnze825",
}

function AdminService.HasTitle(player: any): boolean
	if AdminService.IsOwner(player) then
		return true
	end
	local id = userIdOf(player)
	return id ~= nil and TITLED[id] ~= nil and ALLOWED[id] ~= nil
end

-- Who is in this server by UserId. A seam: AdminSpec, which has no real
-- players in Edit, answers it with stand-ins.
function AdminService.FindPlayer(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function refuse(message: string): Reply
	return { ok = false, message = message }
end

-- Somebody the list does not name asked. Said in the log, at most once a minute
-- per sender, so a forged flood cannot become a flood of warnings.
local function noteStranger(sender: any)
	local key: any = if type(sender) == "table" or typeof(sender) == "Instance" then sender else "?"
	local now = os.clock()
	if now - (lastStranger[key] or -math.huge) >= 60 then
		lastStranger[key] = now
		warn(string.format("[Seed/AdminService] refused an admin request from %s (UserId %s): not on the allowlist.",
			nameOf(sender), tostring(userIdOf(sender))))
	end
end

--==============================================================================
-- THE RECORD
--
-- Every action that changed something, in the server log with the admin, the
-- target, the action, the amount actually added (and the amount asked, where
-- the cap cut it short) and the time in UTC -- and for a spawn (2026-10-07)
-- the species, the size, the form and the quantity. The last fifty are also
-- kept in memory for Audit.
--==============================================================================
local function record(admin: any, target: any, action: string, amount: number?, asked: number?, item: SpawnItem?)
	local entry: AuditEntry = {
		at = DateTime.now():ToIsoDate(),
		admin = userIdOf(admin) or 0,
		target = userIdOf(target) or 0,
		action = action,
		amount = amount,
		asked = asked,
		species = if item then item.species else nil,
		size = if item then item.size else nil,
		form = if item then item.form else nil,
		quantity = if item then item.quantity else nil,
	}
	table.insert(audit, entry)
	if #audit > AUDIT_KEEP then
		table.remove(audit, 1)
	end
	local amountText = ""
	if amount then
		amountText = "  amount " .. commas(amount)
		if asked and asked ~= amount then
			amountText ..= " (asked " .. commas(asked) .. ", capped)"
		end
	end
	if item then
		amountText ..= string.format("  species %s  size %s (%d)  form %s  quantity %d", item.species,
			SeedData.TierName(item.size), item.size, item.form, item.quantity)
	end
	local targetText = if target ~= nil
		then string.format("target %d (%s)", entry.target, nameOf(target))
		else "the whole server"
	log(string.format("%s  admin %d (%s) -> %s  %s%s", entry.at, entry.admin, nameOf(admin),
		targetText, action, amountText))
end

function AdminService.Audit(): { AuditEntry }
	return table.clone(audit)
end

--==============================================================================
-- ADD MONEY, ADD SPEED
--==============================================================================
local function wholeAmount(value: any, limit: number): number?
	-- NaN fails every comparison, so it is tested rather than compared; the
	-- two infinities fail the range check.
	if type(value) ~= "number" or value ~= value then
		return nil
	end
	if value < 1 or value > limit or value ~= math.floor(value) then
		return nil
	end
	return value
end

local function grant(admin: any, target: Player, action: string, amount: any): Reply
	local money = action == "AddMoney"
	local limit = if money then AdminService.Config.MaxMoney else AdminService.Config.MaxSpeed
	local n = wholeAmount(amount, limit)
	if not n then
		return refuse(string.format("Enter a whole number from 1 to %s.", commas(limit)))
	end
	local field = if money then "Cash" else "Speed"
	local cap = if money then SAVE.MaxCash else SAVE.MaxSpeedScore
	local noun = if money then "cash" else "Speed"
	local profile: any = PlayerDataService.Get(target)
	if not profile then
		return refuse(string.format("%s's profile has not loaded yet. Try again in a moment.", target.Name))
	end
	local before = tonumber(profile[field]) or 0
	if before >= cap then
		return refuse(string.format("Nothing added: %s is already at the %s limit.", target.Name, noun))
	end

	local reason = "an admin grant from " .. nameOf(admin)
	local paid = if money
		then EconomyService.PayReward(target, n, reason)
		-- "admin": a Speed milestone this crosses is passed with no prize (2026-10-08).
		else TreadmillService.PayReward(target, n, reason, "admin")
	if not paid then
		return refuse("The grant was refused; nothing changed.")
	end
	local now: any = PlayerDataService.Get(target)
	local after = tonumber(now and now[field]) or before
	local added = math.max(0, after - before)
	record(admin, target, action, added, n)

	local shown = if money then "$" .. commas(added) else commas(added) .. " Speed"
	local message = string.format("Added %s to %s.", shown, target.Name)
	if added < n then
		message = string.format("Added %s to %s -- the %s limit stopped the rest of %s.", shown,
			target.Name, noun, if money then "$" .. commas(n) else commas(n))
	end
	return { ok = true, message = message, added = added }
end

--==============================================================================
-- RESET PLAYER PROGRESS: BACK TO A FRESH ACCOUNT, SAVED -- OR IT SAYS IT WAS NOT
--
--   1. The admin typed the target's username; checked again here, where it
--      counts, not only on the button.
--   2. The profile is loaded AND saving. A temporary profile (DataStores out of
--      reach) cannot be reset for real, so it is refused before anything moves.
--   3. In ONE resumption, nothing yielding: off the mill, the carried pod
--      forfeited, their trap lifted, the garden cleared, every Tool in the bag
--      and the hands destroyed, and the profile reset IN PLACE. Nothing old is
--      left for a hotbar sync, a garden persist or the autosave to write back.
--   4. The plot and the mill rebuilt at the fresh tiers; weapons matched to the
--      fresh (empty) loadout; WalkSpeed recomputed from Speed 0.
--   5. SAVED. Only a save that lands is a success.
--   6. A new character at the plot, whose bag is rebuilt from the fresh record
--      -- and the profile packet brings every HUD panel down to it.
--
-- KEPT, by PlayerDataService.ResetProgress: Robux purchase receipts, so nothing
-- already bought is ever granted twice; game passes, which Roblox holds and the
-- profile never did; when the account was created; the Walk Mode setting.
--==============================================================================
local function confirmMatches(typed: any, target: Player): boolean
	if type(typed) ~= "string" or #typed > 64 then
		return false
	end
	local trimmed = string.match(typed, "^%s*(.-)%s*$") or ""
	return trimmed ~= "" and string.lower(trimmed) == string.lower(target.Name)
end

local function resetProgress(admin: any, target: Player, typed: any): Reply
	if not confirmMatches(typed, target) then
		return refuse(string.format("Type %s exactly to confirm the reset. Nothing changed.", target.Name))
	end
	if not PlayerDataService.IsPersistent(target) then
		return refuse(string.format(
			"%s's profile is not saving in this session, so it cannot be reset. Nothing changed.",
			target.Name))
	end
	if resetting[target] then
		return refuse(string.format("A reset for %s is already running.", target.Name))
	end
	resetting[target] = true

	--== 3. ONE RESUMPTION: the world first, then the record ==--
	TreadmillService.Unmount(target)
	CarryService.ForfeitCarry(target, "an admin progress reset")
	CombatService.ClearTrap(target)
	local plot = PlotService.PlotOf(target)
	local plants = if plot then PlantService.ClearGarden(target, plot) else 0
	-- Listed one by one rather than as `{ backpack, character }`: ipairs stops at
	-- a nil, so a player mid-respawn with no Backpack would keep what is in
	-- their hands.
	local containers: { Instance } = {}
	local backpack = target:FindFirstChildOfClass("Backpack")
	if backpack then
		table.insert(containers, backpack)
	end
	if target.Character then
		table.insert(containers, target.Character)
	end
	local tools: { Instance } = {}
	for _, container in ipairs(containers) do
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") then
				table.insert(tools, tool)
				tool:Destroy()
			end
		end
	end
	if not PlayerDataService.ResetProgress(target) then
		resetting[target] = nil
		return refuse(string.format("%s's profile was gone before it could be reset. Nothing was saved.",
			target.Name))
	end
	-- The hotbar record catches up with the emptied hands: the fresh bag, empty.
	CarryService.SyncHeldNow(target, tools)

	--== 4. THE WORLD, REBUILT FROM THE FRESH RECORD ==--
	local fresh: any = PlayerDataService.Get(target)
	PlotService.SetDesiredLevel(target, if fresh then fresh.PlotTier else GameConfig.StartingPlotTier)
	if plot then
		TreadmillService.Rebuild(plot, TreadmillService.TierOf(target))
	end
	WeaponShopService.RefreshTools(target)
	CarryService.RefreshWalkSpeed(target)

	--== 5. SAVED, OR NOT A SUCCESS ==--
	local saved = PlayerDataService.Save(target)

	--== 6. A NEW BODY AT THE PLOT ==--
	-- Whatever the save said: the world and the record already agree.
	if target.Parent == Players then
		pcall(function()
			target:LoadCharacter()
		end)
	end
	resetting[target] = nil

	if not saved then
		return refuse(string.format("%s was reset in this server, but the SAVE DID NOT LAND. The autosave "
			.. "keeps trying; do not treat the reset as done until it has saved.", target.Name))
	end
	record(admin, target, "ResetPlayerProgress", nil, nil)
	return {
		ok = true,
		message = string.format("%s was reset to a fresh account and saved (%d plant(s) and %d item(s) "
			.. "removed). Purchases and game passes were kept.", target.Name, plants, #tools),
	}
end

--==============================================================================
-- START NIGHT, START DAY: THE WHOLE SERVER
--
-- WorldCycleService's own transitions -- the ones the clock runs at a deadline
-- -- asked for now. The barrier, the ejection and its carry forfeits, the pod
-- clear, the guardian reset, the dawn restock and the published deadline that
-- the clock, the music and the lighting read all follow their normal rules, and
-- the cycle carries on from the new phase on its configured durations. Asking
-- for the phase already running changes nothing and says so; a change already
-- under way is never doubled (WorldCycleService serialises them).
--==============================================================================
local function minutes(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function phaseRefusal(why: string, already: string): string
	if why == "ALREADY_NIGHT" or why == "ALREADY_DAY" then
		return already
	elseif why == "BUSY" then
		return "A day/night change is already under way. Try again in a moment."
	end
	return "The change failed; the server log says why. The cycle is still running."
end

local function changePhase(admin: any, action: string): Reply
	local CYCLE = GameConfig.WorldCycle
	if action == "StartNight" then
		local ok, why = WorldCycleService.StartNight()
		if not ok then
			return refuse(phaseRefusal(why, "Already night."))
		end
		record(admin, nil, action, nil, nil)
		return {
			ok = true,
			message = string.format("Night started for everyone in this server. Day returns in %d s, "
				.. "then the cycle carries on.", CYCLE.NightSeconds),
		}
	end
	local ok, why, built, wanted = WorldCycleService.StartDay()
	if not ok then
		return refuse(phaseRefusal(why, "Already day."))
	end
	record(admin, nil, action, nil, nil)
	return {
		ok = true,
		message = string.format("Day started for everyone in this server: nests restocked (%d of %d "
			.. "pods). Night in %s.", built or 0, wanted or 0, minutes(CYCLE.DaySeconds)),
	}
end

--==============================================================================
-- SPAWN: ANY PLANT OR POD, INTO ANYBODY'S BAG IN THIS SERVER (2026-10-07)
--
-- The owner's widening of SECRET ITEMS (2026-10-02: the two Secrets, into the
-- admin's own bag): every species the game has, as a POD or a GROWN PLANT, at
-- any size it really comes in, from one to a whole bag's free room at once, to
-- anybody in this server -- on live servers and in Studio, for both allowlisted
-- accounts. NOT the natural spawn: no nest, no platform, no guardian, no world
-- toast and no day/night change.
--
-- INDISTINGUISHABLE FROM AN EARNED ONE. An item is a species id and a tier, the
-- two things its saved row holds, and both come from SeedData through
-- SpawnCatalog -- the module the console draws its choices from -- so its pod
-- shell, growth, income, hatch and flags are the natural item's: an Invite
-- reward stays Unsellable, a Rain pod keeps its own growth, shell and skipped
-- roll. It goes into the bag through CarryService's own givers, GivePod (a
-- banked pod's builder and row) and GiveHatched with onRecord (an Invite
-- reward's), which count the storage limit and write the saved row, or give
-- nothing.
--
-- CHECKED IN THIS ORDER, after Handle's allowlist and one-a-second limit:
--   1. Spawning is on (the console's own switch; GameConfig.Secret.Enabled, the
--      natural spawn's, is never read or changed here)
--   2. the request is exactly { species, form, size, quantity, request } of
--      those types
--   3. a species SeedData knows by its exact id, POD or GROWN PLANT, a size it
--      really comes in (SpawnCatalog.allows), and 1 .. SAVE.MaxHeld of them
--   4. the target is somebody in THIS server, by UserId; anybody but the sender
--      also needs their username in the fourth word -- the console's confirm,
--      "Give 3 Colossal Lanterncap pods to <name>?"
--   5. a request id answered lately gets that answer again, and nothing more is
--      given; one still running is refused
--   6. no spawn already running for this admin; SpawnCooldown since the last
--   7. the target's profile is loaded and SAVING, and their bag has room for
--      the WHOLE quantity (HeldRoom)
--   8. every item given and recorded -- or, if one cannot be, those already
--      given taken back with their rows (SyncHeldNow), and nothing at all
--   9. ONE save write for the whole request; "saved" only when it landed
--  10. on the record (who, the target, species, size, form, quantity); anybody
--      but the sender is told "An admin gave you ..."
--==============================================================================
local NO_EQUIP = -1

local function malformed(): Reply
	return refuse("Malformed request. Nothing was spawned.")
end

local function toolsOf(player: any): { [Instance]: boolean }
	local set: { [Instance]: boolean } = {}
	local containers = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for i = 1, 2 do
		local container = containers[i]
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then
					set[child] = true
				end
			end
		end
	end
	return set
end

-- The one Tool a give made: in the bag or the hands now, and not before it.
local function newToolOf(player: any, before: { [Instance]: boolean }, speciesId: string): Tool?
	for tool in pairs(toolsOf(player)) do
		if not before[tool] and tool:GetAttribute("SpeciesId") == speciesId then
			return tool :: Tool
		end
	end
	return nil
end

-- "your Bag" for the admin's own, "<name>'s Bag" for anybody else's.
local function bagOf(target: any, own: boolean): string
	return if own then "your Bag" else nameOf(target) .. "'s Bag"
end

local function whose(target: any, own: boolean): string
	return if own then "Your" else nameOf(target) .. "'s"
end

--==============================================================================
-- TELLING THE PLAYER WHO WAS GIVEN SOMETHING
--
-- One line in the game's own notice stack, through the GameEvent verb every
-- client already listens on (Notice.ServerNotice, drawn by ActionToastUI): the
-- words are this file's, so no client carries any of them. A seam, like
-- FindPlayer: AdminSpec's stand-ins have no client, so it records the lines.
--==============================================================================
function AdminService.TellPlayer(player: any, title: string, detail: string?, key: string?)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	local seedGame = ReplicatedStorage:FindFirstChild("SeedGame")
	local remotes = if seedGame then seedGame:FindFirstChild("Remotes") else nil
	local event = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if event and event:IsA("RemoteEvent") then
		pcall(function()
			event:FireClient(player, Notice.ServerNotice, { title = title, detail = detail, key = key })
		end)
	end
end

-- 8 to 10, once every check has passed. Its own function so a failure inside
-- it is caught by the caller and the pending flag always comes down.
local function giveAll(admin: any, target: Player, species: SeedData.Species, size: number, form: string,
	quantity: number, requestId: string): Reply
	local own = target == admin
	local made: { Instance } = {}
	local gave = 0
	local stopped = false
	for _ = 1, quantity do
		local before = toolsOf(target)
		local given
		if form == "pod" then
			given = CarryService.GivePod(target, species.Id, size)
		else
			given = CarryService.GiveHatched(target, species, size, NO_EQUIP, nil, true)
		end
		if not given then
			stopped = true
			break
		end
		gave += 1
		local tool = newToolOf(target, before, species.Id)
		if tool then
			table.insert(made, tool)
		end
	end
	if stopped then
		-- Nothing at all: what this request already gave goes back, and its
		-- rows with it -- SyncHeldNow is the one call that takes rows off, and
		-- only those of the Tools named.
		for _, tool in ipairs(made) do
			tool:Destroy()
		end
		if #made > 0 then
			CarryService.SyncHeldNow(target, made)
		end
		local room, count = CarryService.HeldRoom(target, nil, if form == "pod" then "pod" else nil)
		local stray = gave - #made
		return refuse(string.format("The spawn could not finish, so nothing was spawned (%s: %d/%d, %d free).%s",
			bagOf(target, own), count, if form == "pod" then SAVE.MaxPods else SAVE.MaxHeld, room,
			if stray > 0 then string.format(" %d item(s) could not be taken back: check the Bag.", stray) else ""))
	end

	local words = SpawnCatalog.phrase(species, size, form, quantity)
	local saved = PlayerDataService.Save(target)
	record(admin, target, "Spawn", nil, nil, { species = species.Id, size = size, form = form, quantity = quantity })
	if not own then
		AdminService.TellPlayer(target, string.format("An admin gave you %s!", words), "It's in your Bag.",
			"admin-gift:" .. requestId)
	end
	local done = if own
		then string.format("Spawned %s into your Bag", words)
		else string.format("Gave %s to %s", words, nameOf(target))
	if not saved then
		return {
			ok = true,
			saved = false,
			given = quantity,
			message = done .. " in this server, but the SAVE HAS NOT LANDED yet; the autosave keeps trying.",
		}
	end
	return { ok = true, saved = true, given = quantity, message = done .. " and saved." }
end

local function spawn(admin: any, targetId: any, request: any, confirmName: any): Reply
	--== 1 ==--
	if AdminService.Config.Spawning ~= true then
		return refuse("Spawning is switched off on this server. Nothing was spawned.")
	end
	--== 2: exactly five fields, each of its type ==--
	if type(request) ~= "table" then
		return malformed()
	end
	local fields = 0
	for key in pairs(request) do
		if type(key) ~= "string" or SPAWN_FIELDS[key] ~= true then
			return malformed()
		end
		fields += 1
	end
	local speciesId, form, size, quantity, requestId =
		request.species, request.form, request.size, request.quantity, request.request
	if fields ~= 5 or type(speciesId) ~= "string" or type(form) ~= "string" or type(size) ~= "number"
		or type(quantity) ~= "number" or type(requestId) ~= "string" or #requestId < 8 or #requestId > 64
		or not string.match(requestId, "^[%w%-_]+$")
	then
		return malformed()
	end
	--== 3: something SeedData has, the way it really comes ==--
	local species = if #speciesId <= 64 then SeedData.Get(speciesId) else nil
	if not species then
		return refuse("No species has that id. Nothing was spawned.")
	end
	if not SpawnCatalog.isForm(form) then
		return refuse("Choose POD or GROWN PLANT. Nothing was spawned.")
	end
	if not SpawnCatalog.allows(species, size) then
		return refuse(string.format("%s does not come in that size. Nothing was spawned.", species.Name))
	end
	if quantity ~= quantity or quantity < 1 or quantity > SAVE.MaxHeld or quantity ~= math.floor(quantity) then
		return refuse(string.format("The quantity must be a whole number from 1 to %d. Nothing was spawned.",
			SAVE.MaxHeld))
	end
	--== 4: anybody in this server; anybody else, confirmed by their username ==--
	if type(targetId) ~= "number" or targetId ~= targetId or targetId <= 0 or targetId ~= math.floor(targetId) then
		return refuse("Choose a player first. Nothing was spawned.")
	end
	local target = AdminService.FindPlayer(targetId)
	if target == nil or target.Parent ~= Players then
		return refuse("That player is no longer in this server. Nothing was spawned.")
	end
	local own = target == admin
	if not own and not confirmMatches(confirmName, target) then
		return refuse(string.format("Giving to %s needs the confirm with their username. Nothing was spawned.",
			target.Name))
	end
	--== 5: the same request again ==--
	local answers = spawnAnswers[admin]
	if not answers then
		answers = {}
		spawnAnswers[admin] = answers
	end
	local now = os.clock()
	for id, entry in pairs(answers) do
		if entry.reply ~= nil and now - entry.at > AdminService.Config.SpawnAnswerSeconds then
			answers[id] = nil
		end
	end
	local seen = answers[requestId]
	if seen then
		local answered = seen.reply
		if answered then
			return { ok = answered.ok, saved = answered.saved, given = answered.given,
				message = "Already answered, nothing more spawned: " .. answered.message }
		end
		return refuse("That spawn is still being made. Nothing more was spawned.")
	end
	--== 6 ==--
	if spawnBusy[admin] then
		return refuse("A spawn is already being made. Wait for it to finish.")
	end
	local last = lastSpawn[admin]
	if last and now - last < AdminService.Config.SpawnCooldown then
		return refuse(string.format("Wait %d s between spawns. Nothing was spawned.",
			math.ceil(AdminService.Config.SpawnCooldown - (now - last))))
	end
	--== 7 ==--
	if not PlayerDataService.IsReady(target) then
		return refuse(string.format("%s profile has not loaded yet. Nothing was spawned.", whose(target, own)))
	end
	if not PlayerDataService.IsPersistent(target) then
		return refuse(string.format("%s profile is not saving in this session, so nothing can be spawned.",
			whose(target, own)))
	end
	-- The room of the form asked for (2026-10-09): pods have their own,
	-- Save.MaxPods; grown plants keep Save.MaxHeld.
	local room, count, known = CarryService.HeldRoom(target, nil, if form == "pod" then "pod" else nil)
	if not known then
		return refuse(string.format("%s has not loaded yet. Nothing was spawned.", bagOf(target, own)))
	end
	if room < quantity then
		return refuse(string.format("Not enough room: %s has %d free (%d/%d %s) and %d %s asked for. Nothing was spawned.",
			bagOf(target, own), room, count, if form == "pod" then SAVE.MaxPods else SAVE.MaxHeld,
			if form == "pod" then "pods" else "plants", quantity, if quantity == 1 then "was" else "were"))
	end
	--== 8 to 10, with the request marked as running ==--
	answers[requestId] = { at = now, reply = nil }
	spawnBusy[admin] = true
	local ran, reply = pcall(giveAll, admin, target, species, size, form, quantity, requestId)
	spawnBusy[admin] = nil
	if not ran then
		warn("[Seed/AdminService] a spawn failed: " .. tostring(reply))
		reply = refuse("The server hit an error during the spawn. Check the Bag and the log before trying again.")
	end
	local answer = reply :: Reply
	answers[requestId] = { at = os.clock(), reply = answer }
	if answer.ok then
		lastSpawn[admin] = os.clock()
	end
	return answer
end

--==============================================================================
-- THE WEATHER: EVERY ADMIN'S, FOR THIS SERVER (2026-10-02; all three, 2026-10-07)
--
-- Rain, through WeatherService. It was the owner's own account's alone until
-- 2026-10-07, when the owner opened it to all three: now any allowlisted
-- account, by UserId -- the allowlist is Handle's first check, on the server,
-- for every request; the client names no identity and is believed about
-- nothing. IsOwner stays, for the ADMIN title alone. `verb` is "start" (rain)
-- or "thunder" (a Thunderstorm, 2026-10-02), each with a whole number of
-- seconds, or "end", which ends whichever is running. One event at a time and
-- the rest of its rules are WeatherService's; what it answers is what the
-- console shows. Every change is in the audit with the admin who made it.
--==============================================================================
local function weather(admin: any, verb: any, seconds: any): Reply
	if verb == "start" or verb == "thunder" then
		local W = GameConfig.Weather
		if type(seconds) ~= "number" or seconds ~= seconds or seconds ~= math.floor(seconds)
			or seconds < W.MinSeconds or seconds > W.MaxSeconds then
			return refuse(string.format("Duration must be a whole number of seconds from %d to %d. Nothing changed.",
				W.MinSeconds, W.MaxSeconds))
		end
		local ok, message
		if verb == "thunder" then
			ok, message = WeatherService.StartThunderstorm(admin, seconds)
		else
			ok, message = WeatherService.StartRain(admin, seconds)
		end
		if ok then
			record(admin, nil, "Weather:" .. verb .. ":" .. tostring(seconds), nil, nil)
		end
		return { ok = ok, message = message }
	elseif verb == "end" then
		local ok, message, ended = WeatherService.EndRain(admin)
		if ended then
			record(admin, nil, "Weather:end", nil, nil)
		end
		return { ok = ok, message = message }
	end
	return refuse("Unknown weather request. Nothing changed.")
end

--==============================================================================
-- MINI EVENTS: TICKET DISCO, FOR EVERY SERVER (2026-10-03, GLOBAL)
--
-- Any allowlisted account -- the allowlist is Handle's first check, by the
-- UserId the engine stamped; nothing new is added to it and no other identity
-- is read. `verb` is a mode ("ticketdisco", "disco", "party", "tickets",
-- "podrush") with
-- a whole number of seconds, or "end". One event at a time across every server, a
-- duplicate START that changes nothing and a harmless second END are
-- MiniEventService's rules (the shared record decides); what it answers --
-- including whether the other servers could be told -- is what the console
-- shows. Every admin account runs it, as the owner asked. The weather -- every
-- admin's too since 2026-10-07 -- stays this server's.
--==============================================================================
local function miniEvent(admin: any, verb: any, seconds: any): Reply
	if type(verb) == "string" and MINI_STARTS[verb] == true then
		local M = GameConfig.MiniEvent
		if type(seconds) ~= "number" or seconds ~= seconds or seconds ~= math.floor(seconds)
			or seconds < M.MinSeconds or seconds > M.MaxSeconds then
			return refuse(string.format("Duration must be a whole number of seconds from %d to %d. Nothing changed.",
				M.MinSeconds, M.MaxSeconds))
		end
		local ok, message = MiniEventService.StartGlobal(admin, verb, seconds)
		if ok then
			record(admin, nil, "MiniEvent:" .. verb .. ":" .. tostring(seconds), nil, nil)
		end
		return { ok = ok, message = message }
	elseif verb == "end" then
		local ok, message, ended = MiniEventService.EndGlobal(admin)
		if ended then
			record(admin, nil, "MiniEvent:end", nil, nil)
		end
		return { ok = ok, message = message }
	end
	return refuse("Unknown mini event request. Nothing changed.")
end

--==============================================================================
-- ONE REQUEST
--
-- The whole of the server's side of the console, and the only thing the
-- RemoteFunction calls. Exposed by name for AdminSpec, the same way CombatService
-- exposes its two handlers; no client reaches it except through that remote.
--==============================================================================
function AdminService.Handle(sender: any, action: any, targetId: any, amount: any, confirmName: any): Reply
	if not AdminService.IsAdmin(sender) then
		noteStranger(sender)
		return refuse("Not authorized.")
	end
	local now = os.clock()
	-- Announce rides the same remote with its own three words: the scope
	-- ("server" or "all"), the message, and whether ALL SERVERS was confirmed.
	-- No one-a-second wait for it (2026-10-03, the owner's ask): its own
	-- safeguards are AnnouncementService.Send's. It is still this admin's last
	-- request, so the limit on everything else is unchanged.
	if action == "Announce" then
		lastRequest[sender] = now
		local sent, message, shownId = AnnouncementService.Send(sender, targetId, amount, confirmName)
		if shownId then
			record(sender, nil, "Announce:" .. tostring(targetId) .. (if sent then "" else ":here-only"), nil, nil)
		end
		return { ok = sent, message = message, shown = shownId ~= nil }
	end
	local last = lastRequest[sender]
	if last and now - last < AdminService.Config.MinInterval then
		return refuse("Too fast. Wait a second and try again.")
	end
	lastRequest[sender] = now

	if type(action) ~= "string" or ACTIONS[action] ~= true then
		return refuse("Unknown action.")
	end
	if WHOLE_SERVER[action] then
		return changePhase(sender, action)
	end
	-- SPAWN carries its own checks (spawn): the second word is the target's
	-- UserId, the third the request table, the fourth -- for anybody but the
	-- sender -- the target's username, the console's confirm.
	if action == "Spawn" then
		return spawn(sender, targetId, amount, confirmName)
	end
	-- WEATHER is any allowlisted admin's (checked above; 2026-10-07): the second
	-- word is the verb, the third the duration (weather).
	if action == "Weather" then
		return weather(sender, targetId, amount)
	end
	-- MINI EVENTS are any allowlisted admin's (checked above): the second word
	-- is the verb, the third the duration (miniEvent).
	if action == "MiniEvent" then
		return miniEvent(sender, targetId, amount)
	end
	if type(targetId) ~= "number" or targetId ~= targetId or targetId <= 0
		or targetId ~= math.floor(targetId) then
		return refuse("Choose a player first.")
	end
	local target = AdminService.FindPlayer(targetId)
	if not target or target.Parent ~= Players then
		return refuse("That player is no longer in this server.")
	end
	if not PlayerDataService.IsReady(target) then
		return refuse(string.format("%s's profile has not loaded yet. Try again in a moment.", target.Name))
	end

	if action == "ResetPlayerProgress" then
		return resetProgress(sender, target, confirmName)
	end
	return grant(sender, target, action, amount)
end

--==============================================================================
-- THE CONSOLE, FOR AN ALLOWLISTED PLAYER ONLY
--
-- Built in a thread of its own per player: a PlayerGui arrives a moment after
-- its player, and nothing in Start may wait for it (a boot yield once cost the
-- owner a garden). ResetOnSpawn off, so a respawn -- including the one a reset
-- deals -- leaves it where it was.
--==============================================================================
function AdminService.ProvideConsole(player: any): ScreenGui?
	if not AdminService.IsAdmin(player) then
		return nil
	end
	local template = script:FindFirstChild(TEMPLATE_NAME)
	if not (template and template:IsA("LocalScript")) then
		warn("[Seed/AdminService] the console's client script is missing; no console for " .. nameOf(player))
		return nil
	end
	local playerGui = player:WaitForChild("PlayerGui", 30)
	if not playerGui or player.Parent ~= Players then
		return nil
	end
	local old = playerGui:FindFirstChild(GUI_NAME)
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.ResetOnSpawn = false
	-- Window space: the button stands in the topbar beside the clock.
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	-- Over the HUD and its panels while it is open; the button itself is small.
	gui.DisplayOrder = 60
	gui:SetAttribute("MaxMoney", AdminService.Config.MaxMoney)
	gui:SetAttribute("MaxSpeed", AdminService.Config.MaxSpeed)
	-- How the console DRAWS its controls (2026-10-04; SPAWN 2026-10-07): SPAWN
	-- locked while its switch is off, and the countdowns the server's own waits
	-- run on. Display only: Handle still decides every press. (An IsOwner here
	-- once hid the weather from the other accounts; every admin has it since
	-- 2026-10-07, so the console is told nothing about who the owner is.)
	gui:SetAttribute("Spawning", AdminService.Config.Spawning == true)
	gui:SetAttribute("SpawnCooldown", AdminService.Config.SpawnCooldown)
	gui:SetAttribute("SpawnAnswerSeconds", AdminService.Config.SpawnAnswerSeconds)
	gui:SetAttribute("MinInterval", AdminService.Config.MinInterval)

	local remote = Instance.new("RemoteFunction")
	remote.Name = REMOTE_NAME
	remote.OnServerInvoke = function(sender: Player, action: any, targetId: any, amount: any,
		confirmName: any): Reply
		local ok, reply = pcall(AdminService.Handle, sender, action, targetId, amount, confirmName)
		if ok then
			return reply
		end
		warn("[Seed/AdminService] a request failed: " .. tostring(reply))
		return { ok = false, message = "The server hit an error. Check the log before trying again." }
	end
	remote.Parent = gui

	-- The console's own modules (2026-10-07), from beside the template: what SPAWN
	-- can make (SpawnCatalog) and the console's arithmetic (ConsoleModel). Copies
	-- in this admin's gui only, like the script itself.
	for _, name in ipairs(CONSOLE_MODULES) do
		local module = script:FindFirstChild(name)
		if module and module:IsA("ModuleScript") then
			module:Clone().Parent = gui
		else
			warn("[Seed/AdminService] the console's module " .. name .. " is missing.")
		end
	end
	local client = template:Clone()
	client.Parent = gui
	gui.Parent = playerGui
	log(string.format("console given to %s (%d).", nameOf(player), userIdOf(player) or 0))
	return gui
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function AdminService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
end

--==============================================================================
-- EVERYBODY HERE, AS THE CONSOLE'S TARGET BAR SHOWS THEM (2026-10-07)
--
-- One JSON line: each player's UserId, username and display name, cash and
-- Speed, the bag (rows on the record and the room left -- a pod being carried
-- home keeps its place, as HeldRoom keeps it) and whether the profile is loaded
-- and saving. For the target bar and SPAWN's quantity; DISPLAY ONLY -- a spawn
-- counts the room again (HeldRoom) and refuses what does not fit.
--==============================================================================
local function rosterLine(): string
	local rows = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local profile: any = PlayerDataService.Get(p)
		-- Two rooms since 2026-10-09: the plants' (held, room) and the pods'
		-- (pods, podRoom), where a pod being carried home keeps its place.
		local held, pods = 0, 0
		if profile and type(profile.Held) == "table" then
			for _, row in ipairs(profile.Held) do
				if type(row) == "table" and row.Hatched == true then
					held += 1
				elseif type(row) == "table" then
					pods += 1
				end
			end
		end
		local carrying = if CarryService.IsCarrying(p) then 1 else 0
		table.insert(rows, {
			id = p.UserId,
			name = p.Name,
			display = p.DisplayName,
			cash = if profile then tonumber(profile.Cash) or 0 else nil,
			speed = if profile then tonumber(profile.Speed) or 0 else nil,
			held = held,
			room = if profile then math.max(0, SAVE.MaxHeld - held) else 0,
			pods = pods,
			podRoom = if profile then math.max(0, SAVE.MaxPods - pods - carrying) else 0,
			ready = PlayerDataService.IsReady(p),
			saving = PlayerDataService.IsPersistent(p),
		})
	end
	table.sort(rows, function(a, b)
		return a.id < b.id
	end)
	local ok, text = pcall(function()
		return HttpService:JSONEncode(rows)
	end)
	return if ok and type(text) == "string" then text else "[]"
end
AdminService.RosterLine = rosterLine

-- The global mini event's status line, for the console's MINI EVENTS
-- section, and the roster (above): written once a second onto each admin's
-- own SeedAdmin gui -- which only that admin's client receives -- and only
-- when it changed.
local statusRunning = 0
local function keepStatus()
	statusRunning += 1
	local mine = statusRunning
	task.spawn(function()
		while mine == statusRunning do
			local line: string? = nil
			local roster: string? = nil
			for _, player in ipairs(Players:GetPlayers()) do
				if AdminService.IsAdmin(player) then
					local playerGui = player:FindFirstChildOfClass("PlayerGui")
					local gui = if playerGui then playerGui:FindFirstChild(GUI_NAME) else nil
					if gui then
						if line == nil then
							local ok, text = pcall(MiniEventService.StatusLine)
							line = if ok and type(text) == "string" then text else "status unavailable"
						end
						if roster == nil then
							local ok, text = pcall(rosterLine)
							roster = if ok and type(text) == "string" then text else "[]"
						end
						if gui:GetAttribute("MiniStatus") ~= line then
							gui:SetAttribute("MiniStatus", line)
						end
						if gui:GetAttribute("Roster") ~= roster then
							gui:SetAttribute("Roster", roster)
						end
					end
				end
			end
			task.wait(1)
		end
	end)
end

function AdminService.Start()
	keepStatus()
	table.insert(serviceConnections, Players.PlayerAdded:Connect(function(player)
		task.spawn(AdminService.ProvideConsole, player)
	end))
	-- Anybody already here: Play Solo's player, and everybody on a re-run.
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(AdminService.ProvideConsole, player)
	end
	local count = 0
	for _ in pairs(ALLOWED) do
		count += 1
	end
	log(string.format("Ready. %d account(s) on the allowlist; up to %s cash and %s Speed a request, "
		.. "progress resets saved or refused, night and day for the whole server, one request a second; "
		.. "spawning any plant or pod to anybody here %s (natural Secret spawning %s); the Rain event and "
		.. "mini events by any admin account.", count,
		commas(AdminService.Config.MaxMoney), commas(AdminService.Config.MaxSpeed),
		if AdminService.Config.Spawning == true then "ON" else "off",
		if GameConfig.Secret.Enabled then "ON" else "off"))
end

return AdminService
