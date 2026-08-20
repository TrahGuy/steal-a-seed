--!strict
-- Steal The Artifact :: PlayerDataService
--
-- Owns every player's profile in memory: coins, level, experience, artifact
-- counts, base level, equipment. Loads through SaveService on join, autosaves,
-- and flushes on leave.
--
--==============================================================================
-- THE RULE THIS FILE EXISTS TO ENFORCE
--
-- NOTHING ELSE IN THE GAME MAY WRITE A PROFILE FIELD. Other services call
-- AddCoins / AddExperience / RecordArtifact and get a boolean back. They never
-- receive the profile table itself, because a table handed out is a table
-- somebody eventually mutates in a way this file cannot see, validate or save.
--
-- GetView returns a copy. Deliberately.
--
--==============================================================================
-- A FAILED LOAD IS NOT A NEW PLAYER
--
-- The single most destructive bug a save system can have: the DataStore is
-- briefly unreachable, the game shrugs and hands out a fresh profile, the first
-- autosave writes it over a real account, and an evening -- or a month -- is
-- gone. So a profile whose load FAILED is marked `readOnly` and is never
-- written back. The player can still play the session; they simply do not
-- overwrite anything.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArtifactGame = ReplicatedStorage:WaitForChild("ArtifactGame")
local Shared = ArtifactGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ArtifactData = require(Shared:WaitForChild("ArtifactData"))
local Types = require(Shared:WaitForChild("Types"))

local SaveService = require(script.Parent:WaitForChild("SaveService"))

type Profile = Types.Profile
type ProfileView = Types.ProfileView

local PlayerDataService = {}
PlayerDataService.Priority = 15

local ECONOMY = ArtifactData.Economy

local profiles: { [number]: Profile } = {}
local readOnly: { [number]: boolean } = {}
local loaded: { [number]: boolean } = {}
local dirty: { [number]: boolean } = {}
local profileUpdated: RemoteEvent? = nil
local autosaveRunning = false

local function log(message: string)
	print("[Artifact/PlayerDataService] " .. message)
end

--==============================================================================
-- DEFAULTS
--
-- Built fresh each call. A shared default table would be a table every new
-- player holds a reference to, and the first one to earn a coin would give
-- everybody else a coin too.
--==============================================================================
local function newProfile(): Profile
	return {
		version = GameConfig.Save.CurrentVersion,
		coins = ECONOMY.StartingCoins,
		level = 1,
		experience = 0,
		artifactsCollected = 0,
		artifactsOwned = {},
		baseLevel = 1,
		equipment = {},
		createdAt = os.time(),
		updatedAt = os.time(),
	}
end

--==============================================================================
-- MIGRATION
--
-- Fills in fields a stored profile predates. FORWARD ONLY: every branch here
-- adds or corrects, and none removes. The version gate in SaveService already
-- refused anything newer than this server understands, so by the time a profile
-- reaches here it is this version or older.
--==============================================================================
local function migrate(stored: any): Profile
	local base = newProfile()
	if type(stored) ~= "table" then
		return base
	end

	base.coins = math.max(0, tonumber(stored.coins) or base.coins)
	base.level = math.clamp(tonumber(stored.level) or 1, 1, ECONOMY.MaxLevel)
	base.experience = math.max(0, tonumber(stored.experience) or 0)
	base.artifactsCollected = math.max(0, tonumber(stored.artifactsCollected) or 0)
	base.baseLevel = math.max(1, tonumber(stored.baseLevel) or 1)
	base.createdAt = tonumber(stored.createdAt) or base.createdAt

	if type(stored.artifactsOwned) == "table" then
		for id, count in pairs(stored.artifactsOwned) do
			-- Ids that no longer exist are DROPPED, not carried. A count keyed
			-- to an artifact the game removed is a number nothing can ever
			-- display, and keeping it means the museum total never matches the
			-- museum.
			if type(id) == "string" and ArtifactData.ById[id] and type(count) == "number" then
				base.artifactsOwned[id] = math.max(0, math.floor(count))
			end
		end
	end

	if type(stored.equipment) == "table" then
		for id, owned in pairs(stored.equipment) do
			if type(id) == "string" and owned == true then
				base.equipment[id] = true
			end
		end
	end

	return base
end

--==============================================================================
-- VIEW
--
-- What the client is allowed to know, and a fresh table every time so a caller
-- cannot hand the client a live reference to server state.
--==============================================================================
local function viewOf(profile: Profile): ProfileView
	return {
		coins = profile.coins,
		level = profile.level,
		experience = profile.experience,
		artifactsCollected = profile.artifactsCollected,
		baseLevel = profile.baseLevel,
	}
end

local function push(player: Player)
	local profile = profiles[player.UserId]
	local remote = profileUpdated
	if profile and remote then
		remote:FireClient(player, viewOf(profile))
	end
end

function PlayerDataService.GetView(player: Player): ProfileView?
	local profile = profiles[player.UserId]
	return if profile then viewOf(profile) else nil
end

function PlayerDataService.IsLoaded(player: Player): boolean
	return loaded[player.UserId] == true
end

--==============================================================================
-- MUTATORS
--
-- Every one returns a boolean rather than the new value, so a caller cannot
-- accidentally use a return as an authoritative balance it then caches.
--==============================================================================
function PlayerDataService.AddCoins(player: Player, amount: number): boolean
	local profile = profiles[player.UserId]
	if not profile then
		return false
	end
	if type(amount) ~= "number" or amount ~= amount then
		return false
	end
	-- Clamped at zero. A negative balance is not a state any UI in this game
	-- knows how to draw, and it is always a bug upstream rather than a thing to
	-- represent faithfully.
	profile.coins = math.max(0, profile.coins + math.floor(amount))
	dirty[player.UserId] = true
	push(player)
	return true
end

function PlayerDataService.AddExperience(player: Player, amount: number): boolean
	local profile = profiles[player.UserId]
	if not profile or type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return false
	end

	profile.experience += math.floor(amount)
	local levelled = false
	while profile.level < ECONOMY.MaxLevel
		and profile.experience >= ECONOMY.ExperiencePerLevel * profile.level do
		profile.experience -= ECONOMY.ExperiencePerLevel * profile.level
		profile.level += 1
		levelled = true
	end
	if levelled then
		log(string.format("%s reached level %d.", player.Name, profile.level))
	end

	dirty[player.UserId] = true
	push(player)
	return true
end

function PlayerDataService.RecordArtifact(player: Player, artifactId: string): boolean
	local profile = profiles[player.UserId]
	if not profile or not ArtifactData.ById[artifactId] then
		return false
	end
	profile.artifactsOwned[artifactId] = (profile.artifactsOwned[artifactId] or 0) + 1
	profile.artifactsCollected += 1
	dirty[player.UserId] = true
	push(player)
	return true
end

function PlayerDataService.SetBaseLevel(player: Player, level: number): boolean
	local profile = profiles[player.UserId]
	if not profile or type(level) ~= "number" or level < 1 then
		return false
	end
	profile.baseLevel = math.floor(level)
	dirty[player.UserId] = true
	push(player)
	return true
end

--==============================================================================
-- PERSISTENCE
--==============================================================================
local function flush(player: Player, force: boolean?): boolean
	local userId = player.UserId
	local profile = profiles[userId]
	if not profile then
		return false
	end
	if readOnly[userId] then
		-- Deliberately silent on the common path. It is warned once at load,
		-- and repeating it every autosave would bury everything else.
		return false
	end
	if not force and not dirty[userId] then
		return false
	end

	local ok = SaveService.Save(userId, profile, force)
	if ok then
		dirty[userId] = false
	end
	return ok
end

PlayerDataService.Flush = flush

local function onPlayerAdded(player: Player)
	local userId = player.UserId
	local stored, ok = SaveService.Load(userId)

	if stored == nil and ok then
		profiles[userId] = newProfile()
		readOnly[userId] = false
		log(string.format("%s (%d): new profile.", player.Name, userId))
	elseif stored ~= nil then
		profiles[userId] = migrate(stored)
		readOnly[userId] = not ok
		log(string.format("%s (%d): loaded -- %d coins, level %d, %d artifact(s)%s.",
			player.Name, userId, profiles[userId].coins, profiles[userId].level,
			profiles[userId].artifactsCollected,
			readOnly[userId] and " [READ ONLY]" or ""))
	else
		-- Load FAILED. Play, but never write.
		profiles[userId] = newProfile()
		readOnly[userId] = true
		warn(string.format(
			"[Artifact/PlayerDataService] %s (%d): profile could not be read. " ..
			"Session is READ ONLY -- nothing will be saved, and nothing will be overwritten.",
			player.Name, userId))
	end

	loaded[userId] = true
	dirty[userId] = false
	push(player)
end

local function onPlayerRemoving(player: Player)
	local userId = player.UserId
	-- Forced: this is the last chance, and the throttle gap must not eat it.
	flush(player, true)
	profiles[userId] = nil
	readOnly[userId] = nil
	loaded[userId] = nil
	dirty[userId] = nil
	SaveService.ForgetThrottle(userId)
end

function PlayerDataService.Init()
	local remotes = ArtifactGame:WaitForChild("Remotes")
	local remote = remotes:FindFirstChild(GameConfig.Remotes.ProfileUpdated)
	if remote and remote:IsA("RemoteEvent") then
		profileUpdated = remote
	end
end

function PlayerDataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Anyone who joined before this connected. In Studio play-solo the local
	-- player is in before server scripts finish, which is exactly the case a
	-- PlayerAdded-only version misses every single run.
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	if not autosaveRunning then
		autosaveRunning = true
		task.spawn(function()
			while true do
				task.wait(GameConfig.Save.AutosaveSeconds)
				for _, player in ipairs(Players:GetPlayers()) do
					flush(player, false)
				end
			end
		end)
	end

	--== SHUTDOWN ==--
	-- BindToClose gets roughly 30 seconds. Saves run in PARALLEL rather than one
	-- after another: eight sequential DataStore writes at a bad moment can
	-- exceed the window, and the players at the end of the list are the ones who
	-- lose their session.
	game:BindToClose(function()
		local pending = 0
		for _, player in ipairs(Players:GetPlayers()) do
			pending += 1
			task.spawn(function()
				flush(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 20
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)

	log(string.format("Ready. Autosave every %ds, store %s.",
		GameConfig.Save.AutosaveSeconds,
		SaveService.IsReachable() and "reachable" or "UNREACHABLE (memory only)"))
end

return PlayerDataService
