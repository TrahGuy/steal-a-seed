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

local function getStore(): DataStore?
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(SAVE.StoreName)
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
local function attemptLoad(userId: number, force: boolean): (LoadStatus, { [string]: any }?)
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

			if heldByOther and not force then
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

-- Public: retries a locked profile a few times before taking it, because the
-- overwhelmingly common cause of a live lock is the player's PREVIOUS server
-- still shutting down, and that resolves in seconds.
function SaveService.Load(userId: number): (LoadStatus, { [string]: any }?)
	if available == false then
		return "unavailable", nil
	end

	for attempt = 1, SAVE.LoadAttempts do
		local force = attempt == SAVE.LoadAttempts
		local status, payload = attemptLoad(userId, force)

		if status == "ok" or status == "new" or status == "unavailable" then
			if force and status == "ok" then
				log(string.format("%d: took a stale session lock after %d attempts.",
					userId, attempt))
			end
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

	return "failed", nil
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

	local wrote = false
	local now = os.time()

	local ok, err = pcall(function()
		ds:UpdateAsync(keyFor(userId), function(old)
			local lock = if type(old) == "table" then old.Lock else nil
			if type(lock) == "table" and lock.JobId ~= nil and lock.JobId ~= JOB
				and (now - (tonumber(lock.Stamp) or 0)) < SAVE.SessionLockSeconds then
				-- Somebody took it while we were playing. Their data is newer
				-- than ours by definition, so ours is the copy that loses.
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
		end
		warn(string.format("[Seed/SaveService] save failed for %d: %s", userId, message))
		return false
	end

	if not wrote then
		warn(string.format(
			"[Seed/SaveService] %d: another server holds this profile now. Not overwriting it.",
			userId))
		return false
	end

	lastWrite[userId] = os.clock()
	return true
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
	table.clear(lastWrite)
end

function SaveService.Start()
	log(string.format("Ready. Store %q, schema v%d, autosave %ds, lock %ds.",
		SAVE.StoreName, SAVE.CurrentVersion, SAVE.AutosaveSeconds, SAVE.SessionLockSeconds))
end

return SaveService
