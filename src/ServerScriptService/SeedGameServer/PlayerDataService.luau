--!strict
-- Steal a Seed :: PlayerDataService
--
-- Owns every player's profile in memory: what it contains, what a new one looks
-- like, who may change it, and when it gets written. SaveService does the I/O
-- and knows nothing about the contents; this knows the contents and nothing
-- about DataStores.
--
--==============================================================================
-- WHAT A PROFILE IS lives in ProfileSchema, separated so the validator standing
-- between the DataStore and the game can actually be tested.
--
--==============================================================================
-- WHAT HAPPENS WHEN A PROFILE WILL NOT LOAD
--
-- Three outcomes, deliberately not the same:
--
--   ok / new     -> real profile, saving on.
--   unavailable  -> DataStores are switched off for this session, which is the
--                   normal state of a Studio place without API access. Give a
--                   temporary profile, turn saving OFF, and say so loudly. It
--                   must not kick, or the game becomes untestable in Studio.
--   failed       -> the store exists and would not answer, after five attempts
--                   across roughly fifteen seconds. KICK.
--
-- Kicking looks hostile and is the kind option. The alternative is handing
-- somebody a default profile and letting them play for ninety seconds, at which
-- point the autosave writes those defaults over everything they own. A player
-- who gets bounced with an honest message rejoins in ten seconds; a player whose
-- account is erased does not come back.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))
local SaveService = require(script.Parent:WaitForChild("SaveService"))
local ProfileSchema = require(script.Parent:WaitForChild("ProfileSchema"))

local SAVE = GameConfig.Save

local PlayerDataService = {}
-- After SaveService (5) and PlotService (10).
PlayerDataService.Priority = 20

export type Profile = ProfileSchema.Profile

type Entry = {
	profile: Profile,
	-- Whether this profile may ever be written. False for the temporary one
	-- handed out when DataStores are unreachable -- and checked at every single
	-- write, because "do not save this" has to be a property of the data rather
	-- than something each caller remembers.
	persistent: boolean,
	dirty: boolean,
	loadedAt: number,
}

local entries: { [Player]: Entry } = {}
local replicateDirty: { [Player]: boolean } = {}
local serviceConnections: { RBXScriptConnection } = {}
local profileUpdated: RemoteEvent? = nil
local profileReady: RemoteEvent? = nil
local shuttingDown = false

local function log(message: string)
	print("[Seed/PlayerDataService] " .. message)
end

--==============================================================================
-- READ API
--==============================================================================
function PlayerDataService.IsReady(player: Player): boolean
	return entries[player] ~= nil
end

function PlayerDataService.Get(player: Player): Profile?
	local entry = entries[player]
	return if entry then entry.profile else nil
end

function PlayerDataService.IsPersistent(player: Player): boolean
	local entry = entries[player]
	return entry ~= nil and entry.persistent
end

--==============================================================================
-- WRITE API
--
-- Every mutation goes through here so clamping and dirty-marking cannot be
-- skipped. Nothing hands out the profile table for direct assignment: Get
-- returns it for READING, and a caller that writes to it straight is a caller
-- whose change never gets saved, because nothing marked it dirty.
--
-- NOTE ON RULE 6, "one faucet": these are the MECHANISM, not the policy.
-- EconomyService is to be the only thing that calls AddCash with a positive
-- number. This layer owns storage; it does not decide what earns.
--==============================================================================
local function touch(player: Player)
	local entry = entries[player]
	if entry then
		entry.dirty = true
		replicateDirty[player] = true
	end
end

function PlayerDataService.AddCash(player: Player, amount: number): number?
	local entry = entries[player]
	if not entry or type(amount) ~= "number" or amount ~= amount then
		return nil
	end
	entry.profile.Cash = math.clamp(entry.profile.Cash + amount, 0, SAVE.MaxCash)
	touch(player)
	return entry.profile.Cash
end

function PlayerDataService.AddSpeed(player: Player, amount: number): number?
	local entry = entries[player]
	if not entry or type(amount) ~= "number" or amount ~= amount then
		return nil
	end
	entry.profile.Speed = math.clamp(entry.profile.Speed + amount, 0, SAVE.MaxSpeedScore)
	touch(player)
	return entry.profile.Speed
end

--==============================================================================
-- PLANTS
--
-- Stored as a plain list of { SpeciesId, Slot, PlantedAt }. PlantedAt is
-- os.time(), an ABSOLUTE clock rather than elapsed seconds, so a plant keeps
-- growing while the player is offline instead of pausing when they leave --
-- which is the difference between a garden and a screensaver.
--
-- ProfileSchema deliberately does not validate the contents: it checks that
-- Plants is a table and leaves the shape to whoever owns it. PlantService
-- re-validates every entry on restore, because a slot that has since been
-- removed by a tier change is a real possibility and must not crash a load.
--==============================================================================
--==============================================================================
-- THE HOTBAR IS RECORDED AS IT CHANGES, NOT READ AT SAVE TIME
--
-- The first attempt asked CarryService for a snapshot immediately before every
-- write, which reads well and does not work: the last write of a session
-- happens while the session is being TORN DOWN, and by then the Character --
-- which is where an EQUIPPED Tool lives -- may already be gone. So the save
-- faithfully recorded an empty hotbar and the plant in the player's hands was
-- destroyed, which is the exact bug this field exists to fix.
--
-- Written on change instead, exactly like Plants. The save then serialises what
-- was already true rather than asking a question at the worst possible moment.
--==============================================================================
function PlayerDataService.SetHeld(player: Player, held: { any }): boolean
	local entry = entries[player]
	if not entry or type(held) ~= "table" then
		return false
	end
	entry.profile.Held = held
	touch(player)
	return true
end

function PlayerDataService.SetPlants(player: Player, plants: { any }): boolean
	local entry = entries[player]
	if not entry or type(plants) ~= "table" then
		return false
	end
	entry.profile.Plants = plants
	touch(player)
	return true
end

--==============================================================================
-- THE ALMANAC
--
-- Set-once and never cleared. Called by PlantService the moment a plant renders
-- as grown on a plot with an owner, which also makes the BACKFILL free: restore
-- re-renders an existing garden at whatever stage it is already at, so a player
-- who has been growing Bellchimes since before this existed has them filled in
-- the first time their plot comes back.
--
-- Returns false for an id already known, and does NOT dirty the profile in that
-- case. Without that check this would mark the save dirty once per grown plant
-- per stage change forever, for a table that has not changed.
--==============================================================================
function PlayerDataService.MarkSeen(player: Player, speciesId: string): boolean
	local entry = entries[player]
	if not entry or type(speciesId) ~= "string" or speciesId == "" then
		return false
	end
	if entry.profile.Almanac[speciesId] then
		return false
	end
	entry.profile.Almanac[speciesId] = true
	touch(player)
	return true
end

--==============================================================================
-- THE MILL TIER, WHICH IS THE PLOT TIER'S TWIN
--
-- Same shape, same guards, same reason: a number the server owns that decides
-- what is built on somebody's ground. Kept separate from PlotTier because they
-- are bought separately and neither implies the other.
--==============================================================================
function PlayerDataService.SetMillTier(player: Player, tier: number): boolean
	local entry = entries[player]
	if not entry or type(tier) ~= "number" or tier ~= tier then
		return false
	end
	local clamped = math.floor(math.clamp(tier, 1, #GameConfig.Mill.Tiers))
	if entry.profile.MillTier == clamped then
		return false
	end
	entry.profile.MillTier = clamped
	touch(player)
	return true
end

function PlayerDataService.SetPlotTier(player: Player, tier: number): boolean
	local entry = entries[player]
	if not entry or type(tier) ~= "number" then
		return false
	end
	local clamped = math.clamp(math.floor(tier), 1, #GameConfig.PlotTiers)
	if clamped ~= entry.profile.PlotTier then
		entry.profile.PlotTier = clamped
		touch(player)
	end
	return true
end

--==============================================================================
-- REPLICATION
--
-- Coalesced rather than fired per change. Once plants are paying out, Cash
-- moves several times a second per player; a remote per increment is a remote
-- per increment for no gain, since a client cannot render faster than it draws.
--==============================================================================
local REPLICATE_INTERVAL = 0.25

local function pushProfile(player: Player)
	local entry = entries[player]
	local remote = profileUpdated
	if not (entry and remote) or player.Parent ~= Players then
		return
	end
	pcall(function()
		remote:FireClient(player, entry.profile)
	end)
end

--==============================================================================
-- SAVING
--==============================================================================
local function write(player: Player, release: boolean, reason: string): boolean
	local entry = entries[player]
	if not entry then
		return false
	end
	-- The check that makes "unavailable" safe. It is a property of the entry
	-- rather than a flag each call site remembers, because a call site that
	-- forgets is an account overwritten with defaults.
	if not entry.persistent then
		return false
	end

	entry.profile.LastSeen = os.time()
	local ok = SaveService.Save(player.UserId, entry.profile, release)
	if ok then
		entry.dirty = false
	else
		warn(string.format("[Seed/PlayerDataService] %s: %s save did not write.",
			player.Name, reason))
	end
	return ok
end

function PlayerDataService.Save(player: Player): boolean
	return write(player, false, "manual")
end

--==============================================================================
-- JOIN
--==============================================================================
local function onPlayerAdded(player: Player)
	if entries[player] then
		return
	end

	-- Yields on the DataStore, so it runs off the signal thread: a slow load
	-- must not hold up anything else that cares about PlayerAdded.
	task.spawn(function()
		local status, raw = SaveService.Load(player.UserId)

		-- They can leave during a fifteen-second load.
		if player.Parent ~= Players then
			return
		end

		if status == "failed" or status == "locked" then
			warn(string.format("[Seed/PlayerDataService] %s: load %s. Kicking rather than " ..
				"handing out defaults that would overwrite their save.", player.Name, status))
			player:Kick("Could not load your save. Please rejoin in a moment -- your progress "
				.. "is safe.")
			return
		end

		local persistent = status == "ok" or status == "new"
		local profile = ProfileSchema.Sanitise(raw)

		entries[player] = {
			profile = profile,
			persistent = persistent,
			dirty = status == "new",
			loadedAt = os.clock(),
		}

		if not persistent then
			warn(string.format(
				"[Seed/PlayerDataService] %s is on a TEMPORARY profile -- DataStores are " ..
				"unreachable, so nothing will be saved. In Studio this means Game Settings -> " ..
				"Security -> Enable Studio Access to API Services is off.", player.Name))
		else
			log(string.format("%s loaded (%s): cash %d, speed %d, tier %d.",
				player.Name, status, profile.Cash, profile.Speed, profile.PlotTier))
		end

		-- PLOT TIER GOES HERE when tiers ship. PlotService.OnAssigned is the
		-- hook, and this is the ordering problem it was built for: the plot is
		-- assigned the instant a player joins, while the profile arrives
		-- seconds later, so the plot has to be rebuilt to tier once the profile
		-- says what tier it is. Deliberately not wired yet -- every plot is
		-- tier 1 and nothing changes that.

		if profileReady then
			pcall(function()
				(profileReady :: RemoteEvent):FireClient(player, true, profile, persistent)
			end)
		end
		replicateDirty[player] = true
	end)
end

local function onPlayerRemoving(player: Player)
	local entry = entries[player]
	if entry then
		-- Unconditional, not "if dirty": the last seconds of a session are
		-- exactly the ones worth not losing, and this releases the session lock
		-- so the player's next server does not have to wait it out.
		write(player, true, "leave")
	end
	entries[player] = nil
	replicateDirty[player] = nil
	SaveService.Forget(player.UserId)
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function PlayerDataService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(entries)
	table.clear(replicateDirty)
	shuttingDown = false
end

function PlayerDataService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	if remotes then
		local u = remotes:FindFirstChild(GameConfig.Remotes.ProfileUpdated)
		local r = remotes:FindFirstChild(GameConfig.Remotes.ProfileReady)
		profileUpdated = if u and u:IsA("RemoteEvent") then u else nil
		profileReady = if r and r:IsA("RemoteEvent") then r else nil
	end
	if not profileUpdated then
		warn("[Seed/PlayerDataService] No ProfileUpdated remote. Clients will see nothing.")
	end

	table.insert(serviceConnections, Players.PlayerAdded:Connect(onPlayerAdded))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(onPlayerRemoving))
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	--== REPLICATION LOOP ==--
	task.spawn(function()
		while not shuttingDown do
			task.wait(REPLICATE_INTERVAL)
			for player in pairs(replicateDirty) do
				replicateDirty[player] = nil
				pushProfile(player)
			end
		end
	end)

	--== AUTOSAVE ==--
	-- Staggered by walking one player per tick rather than saving everybody at
	-- once, so six players do not produce six simultaneous DataStore writes
	-- every ninety seconds.
	task.spawn(function()
		while not shuttingDown do
			task.wait(SAVE.AutosaveSeconds / math.max(1, GameConfig.MaxPlayers))
			for player, entry in pairs(entries) do
				if entry.dirty and entry.persistent
					and not SaveService.RecentlyWritten(player.UserId) then
					write(player, false, "autosave")
					break
				end
			end
		end
	end)

	--== SHUTDOWN ==--
	-- The save that matters most. Roblox gives roughly thirty seconds here and
	-- WAITS for this callback, so the writes must happen inside it -- a
	-- task.spawn would return immediately and the server would close mid-write.
	game:BindToClose(function()
		shuttingDown = true
		if RunService:IsStudio() and SaveService.IsAvailable() ~= true then
			return
		end
		local pending = 0
		for player, entry in pairs(entries) do
			if entry.persistent then
				pending += 1
				task.spawn(function()
					write(player, true, "shutdown")
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 20
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)

	log(string.format("Ready. Schema v%d, autosave every %ds, cash capped at %.0e.",
		SAVE.CurrentVersion, SAVE.AutosaveSeconds, SAVE.MaxCash))
end

return PlayerDataService
