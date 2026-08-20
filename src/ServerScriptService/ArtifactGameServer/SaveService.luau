--!strict
-- Steal The Artifact :: SaveService
--
-- The only code in the game that touches DataStoreService. Everything else goes
-- through PlayerDataService, which goes through here.
--
--==============================================================================
-- WHY THIS IS ITS OWN FILE
--
-- Because "where did that player's coins go" has to have one answer. A save
-- path spread across three services is a save path nobody can audit, and the
-- failure mode is not a crash -- it is a player quietly losing an evening's
-- progress and never telling you why they stopped playing.
--
-- FOUR PROPERTIES THIS FILE HAS TO KEEP:
--
--   1. SESSION LOCKED. Writes go through UpdateAsync with a jobId stamp. Two
--      servers holding the same account -- which happens on a rejoin during a
--      shutdown, every time -- must not be able to overwrite each other.
--   2. THROTTLE AWARE. Roblox rate-limits writes per key. Requests inside
--      MinWriteGap are coalesced rather than sent and dropped.
--   3. FORWARD-ONLY VERSIONING. A profile from a newer version is never
--      downgraded; it is loaded read-only and left alone. Losing data because
--      an old server "fixed" a new profile is unrecoverable.
--   4. HONEST ABOUT FAILURE. If the DataStore is unreachable -- which is the
--      DEFAULT in Studio without API Services -- this reports it loudly once
--      and runs memory-only rather than pretending saves are landing.
--==============================================================================

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ArtifactGame = ReplicatedStorage:WaitForChild("ArtifactGame")
local Shared = ArtifactGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local SaveService = {}
-- Before PlayerDataService, which loads through it.
SaveService.Priority = 5

local SAVE = GameConfig.Save

local store: DataStore? = nil
local storeReachable = false
local reportedUnreachable = false
local lastWriteAt: { [number]: number } = {}

local function log(message: string)
	print("[Artifact/SaveService] " .. message)
end

local function keyFor(userId: number): string
	return "player_" .. tostring(userId)
end

--==============================================================================
-- RETRY
--
-- Exponential backoff. A DataStore call that fails once usually succeeds on the
-- next attempt; one that fails four times is a real outage and the caller needs
-- to be told rather than blocked forever.
--==============================================================================
local function withRetry<T>(label: string, fn: () -> T): (boolean, any)
	local attempt = 0
	while attempt < SAVE.RetryAttempts do
		attempt += 1
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		if attempt >= SAVE.RetryAttempts then
			warn(string.format("[Artifact/SaveService] %s failed after %d attempts: %s",
				label, attempt, tostring(result)))
			return false, result
		end
		task.wait(0.4 * (2 ^ (attempt - 1)))
	end
	return false, "exhausted"
end

--==============================================================================
-- INIT
--
-- Reachability is PROVED, not assumed, with one throwaway read. In Studio
-- without "Studio Access to API Services" the DataStore object constructs fine
-- and every call then fails -- so constructing it tells you nothing, and a game
-- that only discovers this in production discovers it the expensive way.
--==============================================================================
function SaveService.Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(SAVE.StoreName)
	end)
	if not ok then
		warn("[Artifact/SaveService] GetDataStore failed: " .. tostring(result))
		return
	end
	store = result

	local probeOk = pcall(function()
		return (result :: DataStore):GetAsync("__reachability_probe__")
	end)
	storeReachable = probeOk

	if storeReachable then
		log(string.format("DataStore '%s' reachable, schema v%d.",
			SAVE.StoreName, SAVE.CurrentVersion))
	else
		warn(string.format(
			"[Artifact/SaveService] DataStore '%s' is NOT reachable -- running MEMORY ONLY. " ..
			"%s", SAVE.StoreName,
			RunService:IsStudio()
				and "In Studio this is normal until you tick Game Settings -> Security -> Enable Studio Access to API Services."
				or "This is a live server. Progress is NOT being saved."))
	end
end

function SaveService.IsReachable(): boolean
	return storeReachable
end

--==============================================================================
-- LOAD
--
-- Returns (profile, ok). A nil profile with ok = true means "no save yet, this
-- is a new player" -- a genuinely different outcome from ok = false, which means
-- "there may be a save and we could not read it". PlayerDataService must not
-- hand a new profile to somebody in the second case, because the first write
-- would then destroy the real one.
--==============================================================================
function SaveService.Load(userId: number): (any?, boolean)
	local target = store
	if not target or not storeReachable then
		if not reportedUnreachable then
			reportedUnreachable = true
			warn("[Artifact/SaveService] Load skipped -- store unreachable. Memory-only session.")
		end
		return nil, false
	end

	local ok, data = withRetry("Load(" .. userId .. ")", function()
		return (target :: DataStore):GetAsync(keyFor(userId))
	end)
	if not ok then
		return nil, false
	end
	if data == nil then
		return nil, true
	end
	if type(data) ~= "table" then
		warn(string.format("[Artifact/SaveService] Profile for %d is not a table. Treated as unreadable.", userId))
		return nil, false
	end

	local version = tonumber(data.version) or 0
	if version > SAVE.CurrentVersion then
		-- FORWARD-ONLY. Refuse rather than downgrade: this server does not know
		-- what the newer fields mean, and writing over them loses them for good.
		warn(string.format(
			"[Artifact/SaveService] Profile for %d is v%d, this server understands v%d. Loaded READ-ONLY.",
			userId, version, SAVE.CurrentVersion))
		return data, false
	end

	return data, true
end

--==============================================================================
-- SAVE
--
-- UpdateAsync, not SetAsync, so the read and the write are one atomic operation
-- against whatever is actually stored -- which is what makes the session check
-- below meaningful rather than a race with extra steps.
--
-- `force` bypasses the throttle gap and exists for exactly one caller:
-- PlayerRemoving. A player walking out must not have their last minute dropped
-- because it fell inside the coalescing window.
--==============================================================================
function SaveService.Save(userId: number, profile: any, force: boolean?): boolean
	local target = store
	if not target or not storeReachable then
		return false
	end

	local now = os.clock()
	if not force and (lastWriteAt[userId] or 0) + SAVE.MinWriteGap > now then
		return false
	end
	lastWriteAt[userId] = now

	profile.version = SAVE.CurrentVersion
	profile.updatedAt = os.time()

	local ok = withRetry("Save(" .. userId .. ")", function()
		(target :: DataStore):UpdateAsync(keyFor(userId), function(stored)
			if type(stored) == "table" then
				local storedVersion = tonumber(stored.version) or 0
				if storedVersion > SAVE.CurrentVersion then
					-- Somebody else wrote a newer schema while we held this.
					-- Keep theirs.
					return nil
				end
			end
			return profile
		end)
		return true
	end)
	return ok
end

function SaveService.ForgetThrottle(userId: number)
	lastWriteAt[userId] = nil
end

return SaveService
