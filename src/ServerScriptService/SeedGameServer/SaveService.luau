--!strict
-- Steal a Seed :: SaveService
--
-- DataStore transport. It knows how to read and write one blob per player under
-- a session lock, and nothing whatsoever about what is inside that blob.
--
--==============================================================================
-- THE ONE RULE: NEVER WRITE A PROFILE YOU DID NOT SUCCESSFULLY READ
--
-- Every account-wiping bug in every simulator ever shipped is the same bug. A
-- DataStore read fails for three seconds, the game shrugs and hands the player a
-- fresh profile because that is the graceful-looking thing to do, and ninety
-- seconds later the autosave writes those defaults over a year of progress.
-- Nothing errored. Nobody noticed until the player did.
--
-- So Load returns a STATUS, not just data, and the four cases are deliberately
-- distinct:
--
--   "ok"          read it, here it is
--   "new"         read it, there was genuinely nothing there
--   "locked"      another server holds it and is still alive
--   "unavailable" DataStores are not reachable at all in this session
--   "failed"      tried, and could not
--
-- "new" and "failed" look identical from the outside -- both mean "no data" --
-- and treating them the same is precisely the bug. Only "ok" and "new" may ever
-- be followed by a write.
--
--==============================================================================
-- THE SESSION LOCK
--
-- Prevents the classic hop: leave server A, join server B before A has written,
-- B loads stale data, B saves over A. Progress gone, nothing errored.
--
-- Load claims the profile inside an UpdateAsync -- read and claim in one atomic
-- operation, because doing it in two is the race it exists to close. Save
-- refuses to write if somebody else now holds the claim.
--
-- A claim older than SessionLockSeconds is assumed dead and taken, because
-- servers crash without releasing anything and a profile locked forever by a
-- machine that no longer exists is worse than a small chance of contention.
--==============================================================================

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))
local SAVE = GameConfig.Save

local SaveService = {}
-- Before PlayerDataService, which is the only thing that calls it.
SaveService.Priority = 5

export type LoadStatus = "ok" | "new" | "locked" | "unavailable" | "failed"

local store: DataStore? = nil
-- nil means "not asked yet". Discovered on first real use rather than by a
-- probe at boot: the first Load finds out, and every later call reuses the
-- verdict. A probe would be a second code path doing the same thing worse.
local available: boolean? = nil
local lastWrite: { [number]: number } = {}

-- Studio leaves JobId empty, so every Studio session shares one id and cannot
-- lock against itself. That is the right behaviour there -- Play Solo and a
-- multi-client test are the same "server" as far as a lock is concerned.
local JOB = game.JobId

local function log(message: string)
	print("[Seed/SaveService] " .. message)
end

local function keyFor(userId: number): string
	return "p_" .. tostring(userId)
end

-- Studio without API access, or a place with DataStores switched off, produces
-- a permanent error rather than a transient one. Retrying it forever would
-- stall every join by RetryAttempts * backoff for no possible benefit.
local function isPermanent(err: string): boolean
	local e = string.lower(err)
	return string.find(e, "studio", 1, true) ~= nil
		or string.find(e, "not allowed", 1, true) ~= nil
		or string.find(e, "403", 1, true) ~= nil
		or string.find(e, "publish", 1, true) ~= nil
end

--==============================================================================
-- WHICH STORE, AND THE STUDIO TEST STORE THAT NO SYNC CAN UNDO
--
-- Automated Play tests never load a real save (AGENTS.md). The first way of
-- doing that pointed Studio's copy of GameConfig at a throwaway name, and any
-- save of GameConfig.luau or any Rojo reconnect quietly put the real name
-- back -- on 2026-09-26 a Play test loaded the owner's real save that way.
--
-- So the switch is a StringValue in ServerStorage, named by
-- SAVE.TestStoreMarker. default.project.json does not map ServerStorage, so
-- Rojo never writes there, and a sync cannot take the switch away. Three
-- rules, all of them one-directional:
--
--   * Only in Studio. A live server never looks, whatever the place holds.
--   * The value must match SAVE.TestStorePattern (Seed...Test_...).
--   * A marker that names anything else refuses EVERY store. It never falls
--     back to the real one: "saves are off" is a safe failure, "saves went to
--     the owner's account" is not.
--
-- Resolved once per server, so a marker added or removed mid-session cannot
-- move a running server between stores.
--==============================================================================
local resolvedStore = false
local storeName: string? = nil
local storeNote = ""

local function resolveStoreName(): string?
	if resolvedStore then
		return storeName
	end
	resolvedStore = true
	storeName, storeNote = SAVE.StoreName, ""
	if RunService:IsStudio() then
		local marker = ServerStorage:FindFirstChild(SAVE.TestStoreMarker)
		if marker then
			local value = if marker:IsA("StringValue") then marker.Value else ""
			if string.find(value, SAVE.TestStorePattern) ~= nil then
				storeName = value
				storeNote = " (STUDIO TEST STORE, from ServerStorage." .. SAVE.TestStoreMarker .. ")"
			else
				storeName = nil
				storeNote = " -- REFUSED: ServerStorage." .. SAVE.TestStoreMarker
					.. " names no test store, so no store is opened"
				available = false
				warn(string.format("[Seed/SaveService] ServerStorage.%s is %q, which is not a test store name. "
					.. "Saves are OFF for this session; the real store was not opened.",
					SAVE.TestStoreMarker, value))
			end
		end
	end
	return storeName
end

local function getStore(): DataStore?
	if store then
		return store
	end
	local name = resolveStoreName()
	if not name then
		return nil
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(name)
	end)
	if ok and result then
		store = result
		return store
	end
	return nil
end

--==============================================================================
-- LOAD
--
-- Read and claim, atomically. The transform runs inside UpdateAsync, so nothing
-- can slip between seeing the profile unlocked and locking it.
--==============================================================================
local function attemptLoad(userId: number): (LoadStatus, { [string]: any }?)
	local ds = getStore()
	if not ds then
		return "unavailable", nil
	end

	local status: LoadStatus = "failed"
	local payload: { [string]: any }? = nil
	local now = os.time()

	local ok, err = pcall(function()
		ds:UpdateAsync(keyFor(userId), function(old)
			if old == nil then
				status = "new"
				payload = nil
				return { Data = nil, Lock = { JobId = JOB, Stamp = now } }
			end

			local lock = old.Lock
			local heldByOther = type(lock) == "table"
				and lock.JobId ~= nil
				and lock.JobId ~= JOB
				and (now - (tonumber(lock.Stamp) or 0)) < SAVE.SessionLockSeconds

			if heldByOther then
				status = "locked"
				-- Returning nil CANCELS the write. The other server keeps its
				-- claim and we have not touched anything.
				return nil
			end

			status = "ok"
			payload = old.Data
			old.Lock = { JobId = JOB, Stamp = now }
			return old
		end)
	end)

	if not ok then
		local message = tostring(err)
		if isPermanent(message) then
			available = false
			warn("[Seed/SaveService] DataStores are unavailable: " .. message)
			return "unavailable", nil
		end
		warn("[Seed/SaveService] load failed for " .. userId .. ": " .. message)
		return "failed", nil
	end

	available = true
	return status, payload
end

-- Public: retries a locked profile a few times before failing, because the
-- overwhelmingly common cause of a live lock is the player's PREVIOUS server
-- still shutting down, and that resolves in seconds.
function SaveService.Load(userId: number): (LoadStatus, { [string]: any }?)
	if available == false then
		return "unavailable", nil
	end

	for attempt = 1, SAVE.LoadAttempts do
		local status, payload = attemptLoad(userId)

		if status == "ok" or status == "new" or status == "unavailable" then
			return status, payload
		end

		if status == "locked" then
			log(string.format("%d: profile is held by another server, waiting (%d/%d).",
				userId, attempt, SAVE.LoadAttempts))
		end
		if attempt < SAVE.LoadAttempts then
			task.wait(SAVE.LoadRetryGap)
		end
	end

	return "locked", nil
end

--==============================================================================
-- SAVE
--
-- Refuses to clobber a profile another server has claimed since we loaded it.
-- `release` clears our claim, and is what a final save on leave passes so the
-- player's next server does not have to wait out the lock.
--==============================================================================
function SaveService.Save(userId: number, payload: { [string]: any }, release: boolean): boolean
	if available == false then
		return false
	end
	local ds = getStore()
	if not ds then
		return false
	end

	local maxAttempts = math.max(1, SAVE.RetryAttempts or 1)
	local backoff = SAVE.RetryBackoff or 1

	for attempt = 1, maxAttempts do
		local wrote = false
		local staleOrLost = false
		local now = os.time()

		local ok, err = pcall(function()
			ds:UpdateAsync(keyFor(userId), function(old)
				local lock = if type(old) == "table" then old.Lock else nil
				if type(lock) == "table" and lock.JobId ~= nil and lock.JobId ~= JOB
					and (now - (tonumber(lock.Stamp) or 0)) < SAVE.SessionLockSeconds then
					-- Somebody took it while we were playing. Their data is newer
					-- than ours by definition, so ours is the copy that loses.
					staleOrLost = true
					return nil
				end
				wrote = true
				return {
					Data = payload,
					Lock = if release then nil else { JobId = JOB, Stamp = now },
				}
			end)
		end)

		if not ok then
			local message = tostring(err)
			if isPermanent(message) then
				available = false
				warn(string.format("[Seed/SaveService] permanent save failure for %d: %s", userId, message))
				return false
			end
			warn(string.format("[Seed/SaveService] save attempt %d/%d failed for %d: %s", attempt, maxAttempts, userId, message))
			if attempt < maxAttempts then
				task.wait(backoff * attempt)
			end
		elseif staleOrLost or not wrote then
			warn(string.format(
				"[Seed/SaveService] %d: another server holds this profile now. Not overwriting it.",
				userId))
			return false
		else
			lastWrite[userId] = os.clock()
			return true
		end
	end

	return false
end

--==============================================================================
-- THE INBOX: WHAT ANOTHER SERVER LEFT FOR A PLAYER (2026-10-06)
--
-- One small blob per player under its own key (i_<userId>), in the SAME store
-- as the profiles -- so the Studio test store holds it too, and no test ever
-- reaches the real one (test_store_off clears every key there). Any server may
-- change it (UpdateAsync: the transform is the whole change, and there is no
-- lock, because nobody holds an inbox); the player's own server reads it and
-- takes what it used. Like the profiles, this knows nothing of what is inside:
-- InviteService puts an invited friend's id there for an inviter who is not in
-- the friend's server.
--
-- Answers false for "not written" -- unavailable, refused or failed -- so the
-- caller keeps what it had and tries again later.
--==============================================================================
local function inboxKey(userId: number): string
	return "i_" .. tostring(userId)
end
SaveService.InboxKey = inboxKey

function SaveService.UpdateInbox(userId: number, transform: (any) -> any): boolean
	if available == false then
		return false
	end
	local ds = getStore()
	if not ds then
		return false
	end
	local maxAttempts = math.max(1, SAVE.RetryAttempts or 1)
	local backoff = SAVE.RetryBackoff or 1
	for attempt = 1, maxAttempts do
		local ok, err = pcall(function()
			ds:UpdateAsync(inboxKey(userId), transform)
		end)
		if ok then
			return true
		end
		local message = tostring(err)
		if isPermanent(message) then
			warn(string.format("[Seed/SaveService] inbox %d: permanent failure: %s", userId, message))
			return false
		end
		warn(string.format("[Seed/SaveService] inbox %d: attempt %d/%d failed: %s", userId, attempt, maxAttempts, message))
		if attempt < maxAttempts then
			task.wait(backoff * attempt)
		end
	end
	return false
end

-- The inbox as it stands (nil when empty), and whether it could be read at all.
function SaveService.ReadInbox(userId: number): (boolean, any)
	if available == false then
		return false, nil
	end
	local ds = getStore()
	if not ds then
		return false, nil
	end
	local ok, value = pcall(function()
		return ds:GetAsync(inboxKey(userId))
	end)
	if not ok then
		warn(string.format("[Seed/SaveService] inbox %d: read failed: %s", userId, tostring(value)))
		return false, nil
	end
	return true, value
end

-- Has this player been written recently enough that another write would be
-- wasting a DataStore request? Autosave asks; a final save on leave does not,
-- because the last few seconds of a session are exactly what must not be lost.
function SaveService.RecentlyWritten(userId: number): boolean
	local last = lastWrite[userId]
	return last ~= nil and (os.clock() - last) < SAVE.MinWriteGap
end

function SaveService.Forget(userId: number)
	lastWrite[userId] = nil
end

-- nil until the first read has happened.
function SaveService.IsAvailable(): boolean?
	return available
end

function SaveService.Init()
	store = nil
	available = nil
	resolvedStore = false
	storeName, storeNote = nil, ""
	table.clear(lastWrite)
end

function SaveService.Start()
	-- The first thing an automated test reads after pressing Play: the store
	-- this server will actually open, and where that name came from.
	local name = resolveStoreName()
	log(string.format("Ready. Store %q%s, schema v%d, autosave %ds, lock %ds.",
		name or "NONE", storeNote, SAVE.CurrentVersion, SAVE.AutosaveSeconds, SAVE.SessionLockSeconds))
end

return SaveService
