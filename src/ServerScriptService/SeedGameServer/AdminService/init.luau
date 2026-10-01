--!strict
-- Steal a Seed :: AdminService
--
-- A small developer console for two accounts: add cash, add Speed, and reset a
-- player's saved progress to a fresh account, on anybody in this server; and
-- start the night or the day for the whole server. Nothing else, and nobody else.
--
--==============================================================================
-- WHY THIS IS NOT DebugService
--
-- DebugService is Studio-only on purpose: the beta's debug panel and its remote
-- were removed on 2026-09-21 (727ebcb), and DebugReleaseSpec keeps them removed.
-- This is the other shape -- five actions, live on published servers, for two
-- named accounts -- so it is a service of its own with one narrow door, and
-- DebugService stays exactly as it is. Nothing here is configured from
-- GameConfig, which every client can read: the allowlist and the limits live in
-- this file, on the server.
--
--==============================================================================
-- WHO: TWO USER IDS, AND NOTHING THAT CAN BE FAKED
--
-- Resolved 2026-09-23 through Roblox's users API in both directions -- name to
-- id (POST users.roblox.com/v1/usernames/users) and id back to name
-- (GET users.roblox.com/v1/users/<id>), both exact -- and nicnicniccoal's again
-- by the engine in Studio Play. The UserId is what the engine stamps on every
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
--   1. the sender is one of the two UserIds
--   2. one request a second per admin, whatever it is
--   3. the action is one of the six
--   4. Start Night and Start Day go to WorldCycleService from here: they act
--      on the whole server and name nobody; Announce goes to
--      AnnouncementService.Send (2026-10-01), which checks its own words
--   5. otherwise the target is a UserId of a player in THIS server, now
--   6. the target's profile has loaded
--   7. for cash and Speed, a finite whole number from 1 to the limit; for a
--      reset, the target's username typed back, and a profile that is saving
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

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
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
}

--==============================================================================
-- THE LIMITS
--
-- Per request. Far under 2^53, so every whole number up to them is exact, and
-- far over anything the shop sells, so one request covers any test. Exposed so
-- AdminSpec can shorten the interval; nothing a client sends can reach it.
--==============================================================================
AdminService.Config = {
	MinInterval = 1,
	MaxMoney = 1e12,
	MaxSpeed = 1e12,
}

local GUI_NAME = "SeedAdmin"
local REMOTE_NAME = "AdminRequest"
local TEMPLATE_NAME = "AdminConsoleUI"
local AUDIT_KEEP = 50

local ACTIONS: { [string]: boolean } = {
	AddMoney = true,
	AddSpeed = true,
	ResetPlayerProgress = true,
	StartNight = true,
	StartDay = true,
	-- 2026-10-01: an announcement, to this server or every server. The checks
	-- past this file's -- the words, the cooldown, the filter -- are
	-- AnnouncementService.Send's; it is reached from nowhere but here.
	Announce = true,
}
-- The two that act on the whole server rather than on a player: no target.
local WHOLE_SERVER: { [string]: boolean } = {
	StartNight = true,
	StartDay = true,
}

export type Reply = { ok: boolean, message: string, added: number? }
export type AuditEntry = {
	at: string,
	admin: number,
	target: number,
	action: string,
	amount: number?,
	asked: number?,
}

local lastRequest: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local lastStranger: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local resetting: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any
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
-- WHICH OF THE TWO IS THE OWNER (2026-10-01)
--
-- The owner's own account -- the one they play and build in Studio as -- by
-- UserId, and only while it is on the allowlist above. Read by nothing but the
-- cosmetic ADMIN title over their head (OwnerTitleService): both accounts keep
-- exactly the same console and the same powers.
--==============================================================================
local OWNER_USER_ID = 4119740186

function AdminService.IsOwner(player: any): boolean
	local id = userIdOf(player)
	return id ~= nil and id == OWNER_USER_ID and ALLOWED[id] ~= nil
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
-- the cap cut it short) and the time in UTC. The last fifty are also kept in
-- memory for Audit.
--==============================================================================
local function record(admin: any, target: any, action: string, amount: number?, asked: number?)
	local entry: AuditEntry = {
		at = DateTime.now():ToIsoDate(),
		admin = userIdOf(admin) or 0,
		target = userIdOf(target) or 0,
		action = action,
		amount = amount,
		asked = asked,
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
		else TreadmillService.PayReward(target, n, reason)
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
	-- Announce rides the same remote with its own three words: the scope
	-- ("server" or "all"), the message, and whether ALL SERVERS was confirmed.
	if action == "Announce" then
		local sent, message, shownId = AnnouncementService.Send(sender, targetId, amount, confirmName)
		if shownId then
			record(sender, nil, "Announce:" .. tostring(targetId) .. (if sent then "" else ":here-only"), nil, nil)
		end
		return { ok = sent, message = message }
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

function AdminService.Start()
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
		.. "progress resets saved or refused, night and day for the whole server, one request a second.", count,
		commas(AdminService.Config.MaxMoney), commas(AdminService.Config.MaxSpeed)))
end

return AdminService
