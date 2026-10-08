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
local OfflineEarnings = require(script.Parent:WaitForChild("OfflineEarnings"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local BiomeData = require(SeedGame:WaitForChild("Shared"):WaitForChild("BiomeData"))
local TutorialData = require(SeedGame:WaitForChild("Shared"):WaitForChild("TutorialData"))
-- The first catch's note (2026-10-08): which hatch takes it back.
local FirstMinute = require(SeedGame:WaitForChild("Shared"):WaitForChild("FirstMinute"))
-- The hotbar's grammar: what a shortcut or a heart may name (2026-10-03).
local HotbarSlots = require(SeedGame:WaitForChild("Shared"):WaitForChild("HotbarSlots"))
-- Launch analytics: told what already happened, never asked anything.
local Metrics = require(script.Parent:WaitForChild("Metrics"))
-- The external new-player traffic feed (off by default): loaded and called
-- inside pcall, so a broken logger can never stop a join or a save.
local trafficLogLoaded, TrafficLog = pcall(require, script.Parent:WaitForChild("TrafficLogService"))

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
	-- Set while the leave save is in flight. The autosave passes it by: a
	-- second, lock-KEEPING write racing the lock-RELEASING one could land last
	-- and hold the player out of their next server for two minutes.
	leaving: boolean?,
	-- The load found NOTHING saved ("new"): a first-time player of the game
	-- (InviteService counts an invited friend only then, 2026-10-06).
	isNew: boolean?,
}

local entries: { [Player]: Entry } = {}
--==============================================================================
-- A REJOIN WAITS FOR THE LEAVE SAVE IT WOULD OTHERWISE RACE
--
-- UserId -> leave saves in flight on THIS server. The session lock cannot tell
-- a rejoin to the same server apart from the session that just ended -- same
-- JobId -- so a quick leave-and-back could load the save as it stood BEFORE
-- the leave save landed, and the next write of the new session would put that
-- older copy back over it. Found reading the leave path on 2026-09-26; a rejoin
-- now waits (LEAVE_SAVE_WAIT seconds at most) for this server's own write.
--==============================================================================
local leavingSaves: { [number]: number } = {}
local LEAVE_SAVE_WAIT = 30
-- UserId -> a write for them is in flight on this server (see write()).
local writing: { [number]: boolean } = {}
local WRITE_WAIT = 30
local replicateDirty: { [Player]: boolean } = {}

-- The player-list columns, per player. See THE PLAYER LIST.
type Stats = {
	folder: Folder,
	speed: StringValue,
	cash: StringValue,
}
local stats: { [Player]: Stats } = {}
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

-- Server success paths only. No client can submit a milestone or step number.
function PlayerDataService.RecordTutorial(player: Player, milestone: string): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players then return false end
	if not TutorialData.Record(entry.profile.Tutorial, milestone) then return false end
	touch(player)
	-- The first time ever, and only then: Record said so.
	Metrics.milestone(player, milestone, entry.profile.Tutorial)
	return true
end

-- Whether a guide step is done: nil while the record has not arrived, which a
-- caller must read as "do not know" -- never as "not done".
function PlayerDataService.TutorialDone(player: Player, milestone: string): boolean?
	local entry = entries[player]
	if not entry then
		return nil
	end
	return entry.profile.Tutorial.Done[milestone] == true
end

--==============================================================================
-- THE FIRST MINUTE (2026-10-08; FirstMinute)
--
-- RecordStarter: the starter pod went into this profile's garden, planted at
-- `plantedAt`. Once ever -- refused when one was already given -- and called by
-- PlantService in the same step that puts the row in the bed, so a save holds
-- the flag and the pod together or neither.
--
-- RecordFirstCatch / TakeFirstCatch: CarryService writes down the pod taken
-- while `steal` is not done; the first hatch of that species at that size takes
-- the note back, once, and its reveal says so. Words ride on it and nothing
-- else, so a note nobody ever hatches costs nothing.
--==============================================================================
function PlayerDataService.RecordStarter(player: Player, plantedAt: number): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players then return false end
	if type(plantedAt) ~= "number" or plantedAt ~= plantedAt or plantedAt <= 0 then return false end
	local profile = entry.profile :: any
	if (tonumber(profile.StarterAt) or 0) > 0 then return false end
	profile.StarterAt = math.floor(plantedAt)
	touch(player)
	return true
end

function PlayerDataService.RecordFirstCatch(player: Player, speciesId: string, tier: number): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players then return false end
	if type(speciesId) ~= "string" or type(tier) ~= "number" then return false end
	local profile = entry.profile :: any
	profile.FirstCatchSpecies = speciesId
	profile.FirstCatchTier = tier
	touch(player)
	return true
end

function PlayerDataService.TakeFirstCatch(player: Player, speciesId: string, tier: number): boolean
	local entry = entries[player]
	if not entry then return false end
	if not FirstMinute.takeCatch(entry.profile, speciesId, tier) then return false end
	touch(player)
	return true
end

--==============================================================================
-- WALK MODE: THE PROFILE IS THE TRUTH, THE ATTRIBUTE IS THE COPY
--
-- Two writes, in this order: the profile, then the replicated attribute. The HUD
-- renders the attribute, so a client that lies to itself about the switch is a
-- client that disagrees with its own screen for one frame and then does not.
--
-- PUBLISHED SEPARATELY from the setter because it also has to happen on LOAD,
-- where nobody toggled anything -- see the profile-ready path in Start. An
-- unpublished profile field would be a saved preference the HUD never showed.
--
-- IT DOES NOT TOUCH WalkSpeed. CarryService owns that and reads this attribute at
-- the end of its own calculation; asking it to recompute is the caller's job, and
-- the caller is the one service that knows whether a character exists yet.
--==============================================================================
function PlayerDataService.PublishWalkMode(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	local on = entry.profile.WalkMode == true
	if player:GetAttribute(GameConfig.Attributes.WalkMode) ~= on then
		player:SetAttribute(GameConfig.Attributes.WalkMode, on)
	end
end

function PlayerDataService.SetWalkMode(player: Player, on: any): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players or type(on) ~= "boolean" then
		return false
	end
	if entry.profile.WalkMode == on then
		-- Nothing changed, so nothing is saved and nothing is replicated. A held
		-- button or a double tap costs one comparison.
		return false
	end
	entry.profile.WalkMode = on
	touch(player)
	PlayerDataService.PublishWalkMode(player)
	return true
end

function PlayerDataService.WalkModeOf(player: Player): boolean
	local entry = entries[player]
	return entry ~= nil and entry.profile.WalkMode == true
end

--==============================================================================
-- DISCO DANCING (2026-10-03): THE THIRD SAVED SETTING, WALK MODE'S THREE MOVES
--
-- The profile holds it (ON by default), this stamps the attribute the dancing
-- client reads, and the one GameEvent verb in Start changes it -- a boolean
-- and nothing else. Only the player's own avatar is affected, on their screen
-- and (because a character's animation replicates) on everybody else's.
--==============================================================================
function PlayerDataService.PublishDiscoDance(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	local on = (entry.profile :: any).DiscoDance ~= false
	if player:GetAttribute(GameConfig.Attributes.DiscoDance) ~= on then
		player:SetAttribute(GameConfig.Attributes.DiscoDance, on)
	end
end

function PlayerDataService.SetDiscoDance(player: Player, on: any): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players or type(on) ~= "boolean" then
		return false
	end
	local profile = entry.profile :: any
	if (profile.DiscoDance ~= false) == on then
		return false
	end
	profile.DiscoDance = on
	touch(player)
	PlayerDataService.PublishDiscoDance(player)
	return true
end

--==============================================================================
-- MENU SIZE: THE SECOND SAVED SETTING, THE SAME THREE MOVES AS WALK MODE
--
-- The profile holds it, this stamps the attribute every menu reads, and the one
-- GameEvent verb in Start changes it. Anything that is not a GameConfig.MenuSize
-- option is refused here -- the attribute is presentation, but the profile is
-- the save, and junk in it would outlive the client that sent it.
--==============================================================================
function PlayerDataService.PublishMenuSize(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	local id = (entry.profile :: any).MenuSize
	if GameConfig.menuSizeScale(id) == nil then
		id = GameConfig.MenuSize.Default
	end
	if player:GetAttribute(GameConfig.Attributes.MenuSize) ~= id then
		player:SetAttribute(GameConfig.Attributes.MenuSize, id)
	end
end

function PlayerDataService.SetMenuSize(player: Player, id: any): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players or GameConfig.menuSizeScale(id) == nil then
		return false
	end
	local profile = entry.profile :: any
	if profile.MenuSize == id then
		return false
	end
	profile.MenuSize = id
	touch(player)
	PlayerDataService.PublishMenuSize(player)
	return true
end

--==============================================================================
-- THE LIKE REMINDER'S STATE (2026-10-01; GameConfig.HatchBonus)
--
-- The profile is the truth and the attribute the copy, as with Walk Mode:
-- "pending", "shown", or nil before the hatch bonus is earned. Set to
-- "pending" only by WheelService.GrantHatchBonus, in the bonus's own step;
-- moved on to "shown" only by the client's report that it was shown, which
-- carries nothing and grants nothing. Answers whether it changed.
--==============================================================================
function PlayerDataService.PublishLikeReminder(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	local state = (entry.profile :: any).LikeReminder
	local value = if state == "pending" or state == "shown" then state else nil
	if player:GetAttribute(GameConfig.Attributes.LikeReminder) ~= value then
		player:SetAttribute(GameConfig.Attributes.LikeReminder, value)
	end
end

function PlayerDataService.MarkLikeReminderShown(player: Player): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players then
		return false
	end
	local profile = entry.profile :: any
	if profile.LikeReminder ~= "pending" then
		return false
	end
	profile.LikeReminder = "shown"
	touch(player)
	PlayerDataService.PublishLikeReminder(player)
	return true
end

function PlayerDataService.MenuSizeOf(player: Player): string
	local entry = entries[player]
	local id = entry and (entry.profile :: any).MenuSize
	return if GameConfig.menuSizeScale(id) ~= nil then id else GameConfig.MenuSize.Default
end

--==============================================================================
-- THE BONUS CHEST'S THREE FIELDS, WRITTEN TOGETHER
--
-- BonusChestService is the only caller: a claim writes all three at once, and
-- a claim whose save failed writes back exactly what was there before. The
-- service owns the rules; this owns the storage, the same split as AddCash.
--
-- No player.Parent test, unlike the setters above, and that is deliberate: a
-- claim's save can be in flight when the player leaves, and the leave save
-- waits for it (see write). If that save failed, the rollback has to land
-- BEFORE the leave save writes -- so it must still be allowed while leaving.
--==============================================================================
function PlayerDataService.SetChest(player: Player, nextAt: number, boost: string, endsAt: number): boolean
	local entry = entries[player]
	if not entry or type(boost) ~= "string"
		or type(nextAt) ~= "number" or nextAt ~= nextAt
		or type(endsAt) ~= "number" or endsAt ~= endsAt then
		return false
	end
	local profile = entry.profile
	profile.ChestNextAt = math.floor(nextAt)
	profile.ChestBoost = boost
	profile.ChestBoostEndsAt = math.floor(endsAt)
	touch(player)
	return true
end

-- The pedestal spends a pod and starts its clock in one synchronous server
-- transaction. The service owns eligibility; this setter owns persistence.
function PlayerDataService.SetSacrifice(player: Player, nextAt: number, endsAt: number): boolean
	local entry = entries[player]
	if not entry or type(nextAt) ~= "number" or nextAt ~= nextAt
		or type(endsAt) ~= "number" or endsAt ~= endsAt then
		return false
	end
	entry.profile.SacrificeNextAt = math.floor(nextAt)
	entry.profile.SacrificeEndsAt = math.floor(endsAt)
	touch(player)
	return true
end

--==============================================================================
-- THE WHEEL'S FIELDS, CHANGED TOGETHER (2026-09-27)
--
-- A spin moves a balance AND records its prize in one step, and a completion
-- moves the daily window AND a balance in one; WheelService does each inside
-- `change`, synchronously, so no other thread can see half of it. `change`
-- returns whether it changed anything; only then is the profile marked for
-- saving and sent to its owner.
--==============================================================================
function PlayerDataService.UpdateWheel(player: Player, change: (Profile) -> boolean): boolean
	local entry = entries[player]
	if not entry then
		return false
	end
	if change(entry.profile) then
		-- Every WheelEarned write passes here, so a ticket stack spent to 0
		-- loses its shortcut (the slot turns faint) and its heart here too.
		HotbarSlots.prune(entry.profile)
		touch(player)
		return true
	end
	return false
end

--==============================================================================
-- INVITE A FRIEND'S FIELDS, CHANGED TOGETHER (2026-10-06)
--
-- InviteService changes InviteIds, InviteGranted and InviteSeen inside
-- `change`, synchronously -- a form's grant and its Held row in one
-- resumption -- and returns whether it changed anything; only then is the
-- profile marked for saving and the three attributes published.
--==============================================================================
function PlayerDataService.UpdateInvites(player: Player, change: (Profile) -> boolean): boolean
	local entry = entries[player]
	if not entry then
		return false
	end
	if change(entry.profile) then
		touch(player)
		PlayerDataService.PublishInvites(player)
		return true
	end
	return false
end

-- Whether this session's load found nothing saved: a first-time player.
function PlayerDataService.IsNewProfile(player: Player): boolean
	local entry = entries[player]
	return entry ~= nil and entry.isNew == true
end

-- The three numbers every invite screen reads (GameConfig.InviteRewards.Attributes):
-- friends counted, forms given, and whether the panel has been seen since.
function PlayerDataService.PublishInvites(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	local A = GameConfig.InviteRewards.Attributes
	local p = entry.profile :: any
	player:SetAttribute(A.Count, #(p.InviteIds or {}))
	player:SetAttribute(A.Granted, p.InviteGranted or 0)
	-- The invite plants ever given, by the track or the wheel (2026-10-08).
	player:SetAttribute(A.Owned, table.concat(p.InviteOwned or {}, ","))
	player:SetAttribute(A.Seen, p.InviteSeen == true)
end

--==============================================================================
-- SAVED INSTANT HATCHES (2026-09-30)
--
-- One credit is an Instant Hatch purchase kept for later (see PlantService.
-- InstantHatch): `delta` is +1 for one granted and -1 for one spent. Whole
-- numbers only, never below zero, never past SAVE.MaxInstantCredits -- a change
-- that would break one of those is refused and changes nothing. Synchronous,
-- like every writer here, so a receipt's credit and its ledger entry reach the
-- same save. Answers the new balance, or nil when refused.
--==============================================================================
function PlayerDataService.AddInstantCredits(player: Player, delta: number): number?
	local entry = entries[player]
	if not entry or type(delta) ~= "number" or delta ~= delta or delta == 0
		or delta ~= math.floor(delta) then
		return nil
	end
	local balance = entry.profile.InstantCredits + delta
	if balance < 0 or balance > SAVE.MaxInstantCredits then
		return nil
	end
	entry.profile.InstantCredits = balance
	touch(player)
	return balance
end

function PlayerDataService.SetTutorialSkipped(player: Player, skipped: boolean): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players or type(skipped) ~= "boolean" then return false end
	if not TutorialData.SetSkipped(entry.profile.Tutorial, skipped) then return false end
	touch(player)
	Metrics.tutorialSkipped(player, skipped)
	return true
end

--==============================================================================
-- ONE MORE RESERVED POD HANDED OUT
--
-- Server-only, like every other writer here: nothing a client sends can move
-- this, and TutorialPodService is the only caller. It is what makes the
-- reserved pod a bounded gift rather than a faucet -- see TutorialData.
-- MaxPodGrants for why a faucet is the danger, and note that the CAP is
-- enforced by the eligibility rule that reads this, not by this writer, which
-- only counts.
--==============================================================================
function PlayerDataService.RecordPodGrant(player: Player): number?
	local entry = entries[player]
	if not entry or player.Parent ~= Players then return nil end
	local tutorial = entry.profile.Tutorial
	tutorial.PodGrants = (tutorial.PodGrants or 0) + 1
	touch(player)
	return tutorial.PodGrants
end

function PlayerDataService.AddCash(player: Player, amount: number): number?
	local entry = entries[player]
	if not entry or type(amount) ~= "number" or amount ~= amount then
		return nil
	end
	entry.profile.Cash = math.clamp(entry.profile.Cash + amount, 0, SAVE.MaxCash)
	touch(player)
	PlayerDataService.PublishStats(player)
	return entry.profile.Cash
end

--==============================================================================
-- WHO HEARS A SPEED GAIN (2026-10-08, TREADMILL FUN)
--
-- After the score moves up, every listener is told (player, before, after,
-- source). `source` is what the CALLER said the Speed was: nil for earned Speed
-- (the belt, a Biome Harvest, a Speed pack, a wheel prize), "admin" or "debug"
-- for the two consoles -- which is how a milestone is passed without a prize.
-- Pcall'd: a listener can never be the thing that loses a payout.
--==============================================================================
local onSpeedGained: { (Player, number, number, string?) -> () } = {}

function PlayerDataService.OnSpeedGained(fn: (Player, number, number, string?) -> ()): () -> ()
	table.insert(onSpeedGained, fn)
	return function()
		local i = table.find(onSpeedGained, fn)
		if i then
			table.remove(onSpeedGained, i)
		end
	end
end

function PlayerDataService.AddSpeed(player: Player, amount: number, source: string?): number?
	local entry = entries[player]
	if not entry or type(amount) ~= "number" or amount ~= amount then
		return nil
	end
	local before = entry.profile.Speed
	entry.profile.Speed = math.clamp(entry.profile.Speed + amount, 0, SAVE.MaxSpeedScore)
	touch(player)
	PlayerDataService.PublishSpeedTier(player)
	PlayerDataService.PublishStats(player)
	--==========================================================================
	-- THE GUIDE'S TWO SPEED MILESTONES, RECORDED WHERE THE SPEED ACTUALLY MOVES
	--
	-- Here rather than in TreadmillService because this is the function that
	-- OWNS the score: any future faucet routes through it, and a milestone hung
	-- off the mill would quietly stop being true. Both calls are no-ops once
	-- recorded -- Record returns false and nothing is marked dirty -- so this
	-- costs two table lookups on a once-a-second tick.
	--
	-- A positive gain is what proves training; a refund or clamp is not.
	--==========================================================================
	if amount > 0 then
		PlayerDataService.RecordTutorial(player, "train")
		if entry.profile.Speed >= TutorialData.SpeedTarget then
			PlayerDataService.RecordTutorial(player, "speed")
		end
	end
	local after = entry.profile.Speed
	if after > before then
		for _, fn in ipairs(onSpeedGained) do
			local ok, err = pcall(fn, player, before, after, source)
			if not ok then
				warn("[Seed/PlayerDataService] a Speed listener failed: " .. tostring(err))
			end
		end
	end
	return after
end

--==============================================================================
-- TREADMILL FUN'S MARKS (2026-10-08): the highest Speed milestone passed, and
-- the milestone tickets still owed. Server-only, like every writer here.
--==============================================================================
function PlayerDataService.SetSpeedMilestone(player: Player, milestone: number): boolean
	local entry = entries[player]
	if not entry or type(milestone) ~= "number" or milestone ~= milestone then return false end
	local profile = entry.profile :: any
	if milestone <= (tonumber(profile.SpeedMilestone) or 0) then return false end
	profile.SpeedMilestone = milestone
	touch(player)
	return true
end

function PlayerDataService.AddMilestoneSpinsOwed(player: Player, delta: number): number?
	local entry = entries[player]
	if not entry or type(delta) ~= "number" or delta ~= delta or delta ~= math.floor(delta) then return nil end
	local profile = entry.profile :: any
	local owed = math.clamp((tonumber(profile.MilestoneSpinsOwed) or 0) + delta, 0, 5)
	profile.MilestoneSpinsOwed = owed
	touch(player)
	return owed
end

--==============================================================================
-- HOW FAST THIS PLAYER LOOKS, TO EVERYBODY ELSE
--
-- One small integer rather than the score itself, deliberately: every OTHER
-- client needs to know which ghost to draw, not how rich you are. The score
-- stays in the profile packet, which only its owner ever receives.
--
-- ON LOAD AS WELL AS ON EARNING, and that is not belt-and-braces -- it was a bug
-- caught in a live session. Published only from AddSpeed, the attribute did not
-- exist until the player's first payout, so somebody rejoining with forty
-- trillion Speed had NO ghosts until they next stood on a mill. The attribute
-- has to describe the profile, not the last thing that happened to it.
--
-- Written only when it actually changes: AddSpeed runs once a second per player
-- on a belt, and an attribute write per tick replicates to every client in the
-- server for a number that moves four times a session.
--==============================================================================
function PlayerDataService.PublishSpeedTier(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	local tier = GameConfig.speedVisualTierFor(entry.profile.Speed)
	if player:GetAttribute(GameConfig.Attributes.SpeedVisualTier) ~= tier then
		player:SetAttribute(GameConfig.Attributes.SpeedVisualTier, tier)
	end
end

--==============================================================================
-- THE PLAYER LIST
--
-- Roblox draws a column for each value in a Folder named `leaderstats` on the
-- Player. Two here: Speed, then Cash -- in that order because the list lays its
-- columns out in the order the values arrive.
--
-- STRINGS, spelled by GameConfig.compact exactly as the corner HUD spells them.
-- A save runs to 1e15, and a number value would print every digit of that into
-- a column a few characters wide.
--
-- WRITTEN WHEN THE SPELLING CHANGES, not when the number does. AddCash runs every
-- second for every player with a garden, each StringValue write replicates to
-- every client in the server, and at 3.43B the spelled value moves once per ten
-- million. So the new string is compared and an unchanged one is skipped.
--
-- Published from AddCash and AddSpeed, which own the two numbers, and built on
-- load. Anything that moved Cash or Speed without them would already be a change
-- that never saves, so there is no third path to cover.
--==============================================================================
local LEADERSTATS = "leaderstats"

local function spellStats(mounted: Stats, profile: Profile)
	local speed = GameConfig.compact(profile.Speed)
	if mounted.speed.Value ~= speed then
		mounted.speed.Value = speed
	end
	-- Spelled exactly as the corner HUD spells it (GameConfig.money): whole
	-- dollars below 100K, so early on this does change about once a second for
	-- an earning player -- one short string to six clients, still skipped
	-- whenever the spelling has not moved.
	local cash = "$" .. GameConfig.money(profile.Cash)
	if mounted.cash.Value ~= cash then
		mounted.cash.Value = cash
	end
end

-- Built, filled, THEN parented, so the list's first sight of the folder already
-- carries both numbers. An older folder on the holder goes first: a re-run must
-- never leave anybody with two sets of columns. It takes the holder rather than
-- a Player so a spec can mount it on a stand-in.
function PlayerDataService.MountStats(holder: Instance, profile: Profile): Stats
	local old = holder:FindFirstChild(LEADERSTATS)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = LEADERSTATS
	local speed = Instance.new("StringValue")
	speed.Name = "Speed"
	speed.Parent = folder
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = folder
	local mounted: Stats = { folder = folder, speed = speed, cash = cash }
	spellStats(mounted, profile)
	folder.Parent = holder
	return mounted
end

function PlayerDataService.PublishStats(player: Player)
	local entry = entries[player]
	local mounted = stats[player]
	if entry and mounted then
		spellStats(mounted, entry.profile)
	end
end

local function dropStats(player: Player)
	local mounted = stats[player]
	stats[player] = nil
	if mounted then
		mounted.folder:Destroy()
	end
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
--==============================================================================
-- EVERY ROW WRITTEN HAS ITS OWN ITEM ID (2026-10-03)
--
-- CarryService gives a row its id as it makes it (MintItem), so the Tool and the
-- row share it. This is the backstop: a row handed in without one, or with an
-- id an earlier row in the same list already has, is given the next number
-- here -- the list is never written with two rows of one name.
--==============================================================================
local function mint(profile: any): string
	local n = math.floor(tonumber(profile.NextItem) or 1)
	if n < 1 then
		n = 1
	end
	profile.NextItem = n + 1
	return tostring(n)
end

function PlayerDataService.MintItem(player: Player): string?
	local entry = entries[player]
	if not entry then
		return nil
	end
	local item = mint(entry.profile)
	touch(player)
	return item
end

function PlayerDataService.SetHeld(player: Player, held: { any }): boolean
	local entry = entries[player]
	if not entry or type(held) ~= "table" then
		return false
	end
	local taken: { [string]: boolean } = {}
	for _, row in ipairs(held) do
		if type(row) == "table" then
			local item = row.Item
			if type(item) ~= "string" or item == "" or taken[item] then
				local was = item
				item = mint(entry.profile)
				while taken[item] do
					item = mint(entry.profile)
				end
				row.Item = item
				-- Every writer gives its rows their ids; reaching here is a writer
				-- that did not, and a shortcut or a heart on the old id is lost.
				warn(string.format("[Seed/PlayerDataService] %s: a held row came in %s; it is item %s now.",
					player.Name, if was == nil then "without an id" else "with a taken id " .. tostring(was), item))
			end
			taken[item] = true
		end
	end
	entry.profile.Held = held
	--==========================================================================
	-- EVERY BAG REMOVAL ENDS HERE (2026-10-03): planting, SELL ALL and SELL ONE,
	-- a sacrifice, the admin's clear -- so an item that is gone loses its
	-- shortcut and its heart in the same write. Prune only removes.
	--==========================================================================
	HotbarSlots.prune(entry.profile)
	touch(player)
	return true
end

--==============================================================================
-- THE HOTBAR, AS THE CLIENT ARRANGED IT (2026-10-03; InventoryService is the verb)
--
-- The whole bar, cleaned against the profile as it is NOW -- so an edit that
-- raced a sale cannot bring the sold item back -- and allowed only the faint
-- slots already on the bar: a client may move or clear one, never make one. A
-- bar that comes out the same as the saved one changes nothing and saves
-- nothing. Answers whether it changed.
--==============================================================================
function PlayerDataService.SetHotbar(player: Player, list: any): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players or type(list) ~= "table" then
		return false
	end
	local profile = entry.profile :: any
	local current = if type(profile.Hotbar) == "table" then profile.Hotbar else HotbarSlots.empty()
	local cleaned = HotbarSlots.clean(profile, list, HotbarSlots.placeholdersIn(current))
	if HotbarSlots.same(cleaned, current) then
		return false
	end
	profile.Hotbar = cleaned
	touch(player)
	return true
end

--==============================================================================
-- THE HEARTS (2026-10-03)
--
-- `refs` names up to Inventory.MaxPerRequest refs -- a group's every copy -- and
-- `on` says which way. Only owned refs, never a faint slot. No total cap:
-- hearts are bounded by what the player owns, and a cap would silently drop the
-- SELL ALL protection a heart promises. Answers how many changed; saves only
-- if some did.
--==============================================================================
function PlayerDataService.SetFavourite(player: Player, refs: any, on: any): number
	local entry = entries[player]
	if not entry or player.Parent ~= Players or type(refs) ~= "table" or type(on) ~= "boolean" then
		return 0
	end
	local profile = entry.profile :: any
	if type(profile.Favourites) ~= "table" then
		profile.Favourites = {}
	end
	local owned = HotbarSlots.owned(profile)
	local changed = 0
	for i = 1, GameConfig.Inventory.MaxPerRequest do
		local ref = refs[i]
		if type(ref) == "string" and owned[ref] and not HotbarSlots.isPlaceholder(ref) then
			if (profile.Favourites[ref] == true) ~= on then
				profile.Favourites[ref] = if on then true else nil
				changed += 1
			end
		end
	end
	if changed > 0 then
		touch(player)
	end
	return changed
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
-- THE BIOME HARVEST, RECORDED
--
-- Set-once, like MarkSeen: false for a biome already recorded, and no dirty
-- mark in that case. AlmanacService pays ONLY when this returns true, which is
-- what makes a double request pay once -- the second one finds the id here.
--
-- Whether the biome is actually finished is the caller's question, answered by
-- AlmanacData off this same profile; this checks only that the id is a biome.
--==============================================================================
function PlayerDataService.RecordMastery(player: Player, biomeId: string): boolean
	local entry = entries[player]
	if not entry or type(biomeId) ~= "string" or not BiomeData.ById[biomeId] then
		return false
	end
	if entry.profile.Mastery[biomeId] then
		return false
	end
	entry.profile.Mastery[biomeId] = true
	touch(player)
	return true
end

--==============================================================================
-- MARIGOLD'S SHELF
--
-- Shaped like MarkSeen above, and for the same three reasons: it is a set, it
-- is set-once, and it REFUSES to dirty the profile for a write that changes
-- nothing. That last one is not tidiness -- an equip button pressed twice, or a
-- purchase re-sent by a client that did not see the first answer, must not each
-- schedule a DataStore write.
--
-- Returning false for "already owned" is also half of the double-charge guard:
-- WeaponShopService charges only when this returns true, so two purchases that
-- somehow reach the till in the same frame can take money exactly once.
--==============================================================================
function PlayerDataService.GrantWeapon(player: Player, weaponId: string): boolean
	local entry = entries[player]
	if not entry or type(weaponId) ~= "string" or weaponId == "" then
		return false
	end
	if entry.profile.Weapons[weaponId] then
		return false
	end
	entry.profile.Weapons[weaponId] = true
	touch(player)
	return true
end

--==============================================================================
-- WHAT IS IN THEIR LOADOUT OFF THAT SHELF
--
-- One slot per category -- "bat" and "trap" -- so equipping a trap cannot clear
-- a bat. The empty string is "nothing in this slot", not nil, because the
-- profile is replicated whole and a nil field is a field the client cannot tell
-- from one that was never sent.
--
-- OWNERSHIP IS RE-CHECKED HERE and not only at the call site. This is the last
-- line before the value is persisted, and a saved slot naming a weapon the
-- player does not own is the one state that survives a rejoin and hands out a
-- free bat. ProfileSchema drops it on load, but a profile that never has to be
-- repaired is better than one that is.
--
-- The CATEGORY is checked by the caller rather than here: this file must not
-- have to know what a bat is. WeaponShopService owns that and refuses first.
--==============================================================================
local LOADOUT_FIELD: { [string]: string } = {
	bat = "EquippedBat",
	trap = "EquippedTrap",
}

function PlayerDataService.SetLoadout(player: Player, category: string,
	weaponId: string): boolean
	local entry = entries[player]
	local field = LOADOUT_FIELD[category]
	if not entry or not field or type(weaponId) ~= "string" then
		return false
	end
	if weaponId ~= "" and not entry.profile.Weapons[weaponId] then
		return false
	end
	if (entry.profile :: any)[field] == weaponId then
		return true
	end
	;(entry.profile :: any)[field] = weaponId
	touch(player)
	return true
end

function PlayerDataService.LoadoutOf(player: Player, category: string): string
	local entry = entries[player]
	local field = LOADOUT_FIELD[category]
	if not entry or not field then
		return ""
	end
	local id = (entry.profile :: any)[field]
	return if type(id) == "string" then id else ""
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

--==============================================================================
-- THE BIOME HIGH-WATER MARK
--
-- RAISES ONLY. Not a setter with a clamp -- a setter that can also go DOWN is
-- one bad caller away from taking Starbloom off somebody, and there is no
-- legitimate reason for this number to fall. If rebirth ever wants to reset it,
-- that is a different function with a different name and a deliberate one.
--
-- A mutation method rather than the milestone tracker reaching into the profile table: this
-- is where the clamp, the no-op check and the dirty flag live, and a caller that
-- wrote entry.profile.HighestBiomeOrder directly would skip all three and its
-- unlock would silently fail to save.
--==============================================================================
function PlayerDataService.RaiseHighestBiome(player: Player, order: number): boolean
	local entry = entries[player]
	if not entry or type(order) ~= "number" or order ~= order then
		return false
	end
	local want = math.floor(math.clamp(order, 1, #BiomeData.Biomes))
	if want <= entry.profile.HighestBiomeOrder then
		return false
	end
	entry.profile.HighestBiomeOrder = want
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

--==============================================================================
-- THE OFFLINE CLAIM, ON THE PLAYER
--
-- Published as attributes so the claim card can read it whenever its script
-- happens to start, before or after the profile lands; server-set, so a client
-- can read it and cannot write it. Cleared the moment the claim is taken.
--==============================================================================
local OFFLINE_ATTR = GameConfig.OfflineEarnings.Attributes

function PlayerDataService.PublishOffline(player: Player)
	local entry = entries[player]
	local profile = if entry then entry.profile else nil
	if not (profile and profile.OfflineCash > 0) then
		for _, name in pairs(OFFLINE_ATTR) do
			player:SetAttribute(name, nil)
		end
		return
	end
	local garden = OfflineEarnings.garden(profile.Plants)
	player:SetAttribute(OFFLINE_ATTR.Seconds, profile.OfflineSeconds)
	player:SetAttribute(OFFLINE_ATTR.Away, profile.OfflineAway)
	player:SetAttribute(OFFLINE_ATTR.Grown, garden.grown)
	player:SetAttribute(OFFLINE_ATTR.Best, garden.best)
	player:SetAttribute(OFFLINE_ATTR.BestTier, garden.bestTier)
	-- Last, so a client watching Cash sees the rest already in place.
	player:SetAttribute(OFFLINE_ATTR.Cash, profile.OfflineCash)
end

--==============================================================================
-- TAKE THE CLAIM, ONCE
--
-- Read and zeroed in one resumption, with no yield between: a second claim in
-- the same frame, or a spammed remote, finds nothing. EconomyService is the
-- only caller and the only thing that turns what this returns into cash.
--==============================================================================
function PlayerDataService.TakeOffline(player: Player): (number?, number, number)
	local entry = entries[player]
	if not entry then
		return nil, 0, 0
	end
	local profile = entry.profile
	local cash, seconds, away = profile.OfflineCash, profile.OfflineSeconds, profile.OfflineAway
	if not (cash > 0) then
		return nil, 0, 0
	end
	profile.OfflineCash = 0
	profile.OfflineSeconds = 0
	profile.OfflineAway = 0
	touch(player)
	PlayerDataService.PublishOffline(player)
	return cash, seconds, away
end

--==============================================================================
-- BACK TO A FRESH ACCOUNT: AdminService's RESET PLAYER PROGRESS
--
-- IN PLACE. The profile table is emptied and refilled from ProfileSchema.Default
-- rather than swapped for a new one, so every service still holding it -- and
-- the autosave, which writes this very table -- sees the reset and nothing else.
-- There is no second copy left anywhere that could write the old progress back.
--
-- KEPT: Receipts, the record that stops a Robux purchase being granted a second
-- time; CreatedAt, when this save first existed; WalkMode, a setting rather than
-- progress; NextItem, so no item id is ever handed out twice. Game passes are not in the profile at all -- PassService asks
-- Roblox -- so nothing here can touch them. Everything else is the schema's
-- default, HighestBiomeOrder included: the one deliberate exception to "nothing
-- in the game lowers it".
--
-- NOT SAVED HERE. The caller clears the world first, so no Tool or plant can be
-- recorded back into the fresh profile, and saves last -- and reports success
-- only if that save lands.
--==============================================================================
function PlayerDataService.ResetProgress(player: Player): boolean
	local entry = entries[player]
	if not entry or player.Parent ~= Players then
		return false
	end
	local profile = entry.profile :: any
	local keep = {
		Receipts = table.clone(profile.Receipts or {}),
		CreatedAt = profile.CreatedAt,
		WalkMode = profile.WalkMode == true,
		MenuSize = if GameConfig.menuSizeScale(profile.MenuSize) ~= nil
			then profile.MenuSize
			else GameConfig.MenuSize.Default,
		-- Not progress (2026-09-27): spins somebody bought, prizes the wheel
		-- still owes, and the cosmetics they won and wear.
		WheelBought = profile.WheelBought or 0,
		-- Nor are Instant Hatches somebody bought and kept for later (2026-09-30).
		InstantCredits = profile.InstantCredits or 0,
		-- The one-time hatch bonus stays claimed and its like reminder keeps its
		-- state (2026-10-01): a reset must not make the bonus claimable again.
		HatchBonusClaimed = profile.HatchBonusClaimed == true,
		-- And the community chest's spins stay claimed (2026-10-01).
		CommunityClaimed = profile.CommunityClaimed == true,
		-- And the starter pod stays given (2026-10-08): one per profile, ever.
		StarterAt = math.max(0, math.floor(tonumber(profile.StarterAt) or 0)),
		-- And treadmill fun's marks (2026-10-08): a milestone is paid once ever,
		-- an owed ticket stays owed, and the belt ticket window keeps running.
		SpeedMilestone = math.max(0, tonumber(profile.SpeedMilestone) or 0),
		MilestoneSpinsOwed = math.max(0, math.floor(tonumber(profile.MilestoneSpinsOwed) or 0)),
		BeltTicketAt = math.max(0, math.floor(tonumber(profile.BeltTicketAt) or 0)),
		BeltTicketCount = math.max(0, math.floor(tonumber(profile.BeltTicketCount) or 0)),
		-- And Invite a Friend's count and the forms it gave (2026-10-06): a reset
		-- must not hand the forms out again, nor forget who was invited.
		InviteIds = table.clone(profile.InviteIds or {}),
		InviteGranted = profile.InviteGranted or 0,
		InviteSeen = profile.InviteSeen == true,
		-- And every invite plant given, and the returning friends paid for
		-- (2026-10-08): neither is ever paid twice.
		InviteOwned = table.clone(profile.InviteOwned or {}),
		InviteReturnIds = table.clone(profile.InviteReturnIds or {}),
		-- And a global mini event's tickets stay counted (2026-10-03): a reset
		-- mid-event must not reopen its per-player cap. A setting stays too.
		EventClaims = table.clone(profile.EventClaims or {}),
		DiscoDance = profile.DiscoDance ~= false,
		LikeReminder = if profile.LikeReminder == "pending" or profile.LikeReminder == "shown"
			then profile.LikeReminder else "",
		WheelPending = table.clone(profile.WheelPending or {}),
		Cosmetics = table.clone(profile.Cosmetics or {}),
		EquippedTrail = profile.EquippedTrail or "",
		-- Item ids are never reused (2026-10-03): restarting them at 1 would let
		-- a shortcut or a heart a client still holds attach to the next new item.
		-- The bar and the hearts themselves are progress, and go.
		NextItem = math.max(1, math.floor(tonumber(profile.NextItem) or 1)),
	}
	local fresh = ProfileSchema.Default() :: any
	table.clear(profile)
	for key, value in pairs(fresh) do
		profile[key] = value
	end
	for key, value in pairs(keep) do
		profile[key] = value
	end
	touch(player)
	PlayerDataService.PublishStats(player)
	PlayerDataService.PublishSpeedTier(player)
	PlayerDataService.PublishWalkMode(player)
	PlayerDataService.PublishMenuSize(player)
	PlayerDataService.PublishDiscoDance(player)
	PlayerDataService.PublishOffline(player)
	PlayerDataService.PublishInvites(player)
	log(string.format("%s's progress was reset in memory (%d receipt(s) kept).", player.Name,
		#keep.Receipts))
	return true
end

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

	--==========================================================================
	-- ONE WRITE PER PLAYER AT A TIME, SO THE RELEASE LANDS LAST
	--
	-- Reproduced 2026-09-26 on a throwaway profile: an autosave that started
	-- 0.3 s before the player left was still in flight when the leave save
	-- began, and it COMMITTED AFTER it -- the record ended up locked by the very
	-- session that had just released it. In Studio that lock names the same
	-- empty JobId and does nothing; on a live server it would hold the player
	-- out of their next server for two minutes. So a write waits for the one
	-- already in flight for the same player, and the release is the last word.
	--==========================================================================
	local userId = player.UserId
	local waitUntil = os.clock() + WRITE_WAIT
	while writing[userId] and os.clock() < waitUntil do
		task.wait(0.1)
	end
	writing[userId] = true
	entry.profile.LastSeen = os.time()
	local called, saved = pcall(SaveService.Save, userId, entry.profile, release)
	writing[userId] = nil
	local ok = called and saved == true
	if not called then
		warn(string.format("[Seed/PlayerDataService] %s: %s save threw: %s", player.Name, reason,
			tostring(saved)))
	end
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
		-- This server may still be writing the session they just left. Load
		-- after it lands, or the load reads the save from before it.
		local waitUntil = os.clock() + LEAVE_SAVE_WAIT
		while leavingSaves[player.UserId] and player.Parent == Players
			and os.clock() < waitUntil do
			task.wait(0.1)
		end
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

		--======================================================================
		-- AN OLD OVERCLOCK BECOMES A MILL, ONCE (2026-10-06)
		--
		-- ProfileSchema.convertOverclock: a tier-10 save with overclock levels
		-- becomes the lowest of tiers 11-14 paying at least what it did, for
		-- nothing; any other tier just loses the levels. Dirty, so the normal
		-- save path keeps it; told to the player once (the attribute below).
		--======================================================================
		local hadOverclock = profile.MillOverclock > 0
		local becameTier = ProfileSchema.convertOverclock(profile)

		--======================================================================
		-- THE ABSENCE IS CREDITED HERE, AND ONLY HERE
		--
		-- LastSeen is when the last session was saved, and the first write of
		-- this session overwrites it -- so this is the one moment it still says
		-- how long they were gone. A saved profile only ("ok"): a new one has no
		-- garden, and a temporary one cannot keep what it is given. Nothing is
		-- paid here; OfflineEarnings records a claim and EconomyService pays it.
		--======================================================================
		local offlineAdded, offlineCredited = 0, 0
		if status == "ok" then
			offlineAdded, offlineCredited = OfflineEarnings.accrue(profile, os.time())
		end

		entries[player] = {
			profile = profile,
			persistent = persistent,
			dirty = status == "new" or offlineAdded > 0 or hadOverclock,
			loadedAt = os.clock(),
			isNew = status == "new",
		}
		-- A brand-new save ("new") in the new-player cohort opens the onboarding
		-- funnel; a returning or temporary profile never does (Metrics).
		Metrics.profileReady(player, profile, status == "new", persistent)
		-- The same verdict for the external feed: only a "new", persistent save
		-- is a new player there (TrafficLogService; staff and Studio never are).
		if trafficLogLoaded then
			pcall((TrafficLog :: any).classified, player, status == "new", persistent)
		end
		PlayerDataService.PublishOffline(player)
		if becameTier then
			-- Read once by MillNotice.client, which says it.
			player:SetAttribute(GameConfig.Attributes.MillOverclockBecame, becameTier)
			log(string.format("%s's overclock became mill tier %d (%s).",
				player.Name, becameTier, GameConfig.Mill.Tiers[becameTier].name))
		end
		if offlineAdded > 0 then
			log(string.format("%s was away %.0f min: garden credited %s for %.0f min (claim now %s).",
				player.Name, profile.OfflineAway / 60, GameConfig.compact(offlineAdded),
				offlineCredited / 60, GameConfig.compact(profile.OfflineCash)))
		end
		--======================================================================
		-- THE TIER IS RIGHT FROM THE FIRST FRAME, AND STAYS RIGHT
		--
		-- ON LOAD, so a rejoining player at a hundred trillion looks like it
		-- immediately rather than after their next payout. AND ON EVERY
		-- RESPAWN: the attribute lives on the Player and does survive a death,
		-- but the client rebuilds its whole ghost pool against the new rig, and
		-- re-stating the tier at that moment is one attribute write that removes
		-- any question about which of the two happened first.
		--======================================================================
		PlayerDataService.PublishSpeedTier(player)
		-- AND THE SAVED WALK MODE, at the same moment and for the same reason: the
		-- HUD renders the attribute, so a player who left with the switch on has to
		-- find it on when they come back rather than after touching it.
		PlayerDataService.PublishWalkMode(player)
		-- And the saved menu size, so the first menu opened is already the size
		-- the player chose.
		PlayerDataService.PublishMenuSize(player)
		-- And the saved disco-dancing choice (2026-10-03).
		PlayerDataService.PublishDiscoDance(player)
		-- And the like reminder's state: a reminder still pending from an earlier
		-- visit is shown at a calm moment of this one (HatchBonusUI).
		PlayerDataService.PublishLikeReminder(player)
		-- And Invite a Friend's count, forms and "!" (2026-10-06): the pedestal shows
		-- the right form from the first frame, with no evolve.
		PlayerDataService.PublishInvites(player)
		table.insert(serviceConnections, player.CharacterAdded:Connect(function()
			PlayerDataService.PublishSpeedTier(player)
			PlayerDataService.PublishWalkMode(player)
			PlayerDataService.PublishMenuSize(player)
			PlayerDataService.PublishDiscoDance(player)
		end))
		-- The player-list columns, off the profile that just loaded.
		stats[player] = PlayerDataService.MountStats(player, profile)

		if not persistent then
			warn(string.format(
				"[Seed/PlayerDataService] %s is on a TEMPORARY profile -- DataStores are " ..
				"unreachable, so nothing will be saved. In Studio this means Game Settings -> " ..
				"Security -> Enable Studio Access to API Services is off.", player.Name))
		else
			log(string.format("%s loaded (%s): cash %d, speed %d, tier %d.",
				player.Name, status, profile.Cash, profile.Speed, profile.PlotTier))
		end

		--======================================================================
		-- THE PLOT LEARNS ITS SIZE, AND THIS IS THE FIRST MOMENT IT CAN
		--
		-- The ordering problem this comment used to reserve space for. A plot is
		-- handed out the instant a player joins; the profile that says how big
		-- it should be arrives from the DataStore seconds later. So the plot is
		-- standing there at Level 1 -- or at whatever its last owner left it --
		-- until right here.
		--
		-- BEFORE the profileReady packet below, deliberately. The client builds
		-- its garden HUD off that packet and reads capacity from the plot's own
		-- attributes; sending "you are Level 4" while the plot in the world
		-- still says Level 1 gives the first frame a HUD that disagrees with the
		-- ground. One line earlier and it never happens.
		--
		-- SetDesiredLevel handles the case where the player has no plot at all
		-- -- a full server, and they are in the queue. It remembers, and the
		-- plot is built to size when their turn comes.
		--======================================================================
		PlotService.SetDesiredLevel(player, profile.PlotTier)

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
		--
		-- Marked first, so the autosave stays off this entry while it yields
		-- and a rejoin to this server waits for it (see leavingSaves).
		local userId = player.UserId
		entry.leaving = true
		leavingSaves[userId] = (leavingSaves[userId] or 0) + 1
		local ok, err = pcall(write, player, true, "leave")
		if not ok then
			warn(string.format("[Seed/PlayerDataService] %s: leave save threw: %s",
				player.Name, tostring(err)))
		end
		local left = (leavingSaves[userId] or 1) - 1
		leavingSaves[userId] = if left > 0 then left else nil
	end
	entries[player] = nil
	replicateDirty[player] = nil
	dropStats(player)
	SaveService.Forget(player.UserId)
end

--==============================================================================
-- THE TWO HANDLERS START CONNECTS, BY NAME
--
-- So a spec can drive a whole join -- the load, the profile, the columns -- and a
-- whole leave against a stand-in player with SaveService stubbed. Server-only,
-- like everything else in this file.
--==============================================================================
PlayerDataService.Join = onPlayerAdded
PlayerDataService.Leave = onPlayerRemoving

--==============================================================================
-- LIFECYCLE
--==============================================================================
--==============================================================================
-- THE GUIDE'S TRAVEL STEP, RECORDED WHERE THE TELEPORT HOME SUCCEEDS (2026-10-08)
--
-- PlotService fires OnTeleportedHome after TELEPORT TO PLOT has moved the
-- player, and only then -- never on a refusal, never for OBBY, BIOMES or the
-- obby's RETURN TO PLOT. RecordTutorial goes through TutorialData.Record, which
-- refuses `travel` until the hatch is done, so a teleport home before the hatch
-- records nothing. Unhooked in Init, so a re-run Start never adds a second one.
--==============================================================================
local unhookTravel: (() -> ())? = nil

function PlayerDataService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	if unhookTravel then
		unhookTravel()
		unhookTravel = nil
	end
	table.clear(entries)
	table.clear(replicateDirty)
	table.clear(leavingSaves)
	table.clear(writing)
	for _, mounted in pairs(stats) do
		mounted.folder:Destroy()
	end
	table.clear(stats)
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

	--==========================================================================
	-- THE MENU SIZE VERB, ON THE REMOTE THE HUD ALREADY OWNS
	--
	-- One string payload, checked against the options before it is written; the
	-- sender is the engine's. Here rather than beside Walk Mode's verb in
	-- CarryService because nothing but the profile is involved: no speed to
	-- recompute, only a setting to keep.
	--==========================================================================
	local channel = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if channel and channel:IsA("RemoteEvent") then
		table.insert(serviceConnections, channel.OnServerEvent:Connect(
			function(player: Player, action: any, payload: any)
				-- The like reminder was shown (2026-10-01): the verb alone, read only
				-- to move "pending" on to "shown", and saved soon after.
				if action == GameConfig.HatchBonus.Reminder.Action then
					if PlayerDataService.MarkLikeReminderShown(player) then
						log(string.format("%s was shown the like reminder.", player.Name))
						task.spawn(PlayerDataService.Save, player)
					end
					return
				end
				-- Disco dancing on or off (2026-10-03): one boolean, kept by the
				-- autosave like the menu size.
				if action == GameConfig.MiniEvent.Dance.Action then
					if PlayerDataService.SetDiscoDance(player, payload) then
						log(string.format("%s turned disco dancing %s.", player.Name, if payload then "on" else "off"))
					end
					return
				end
				if action ~= GameConfig.MenuSize.Action or type(payload) ~= "string" then
					return
				end
				if PlayerDataService.SetMenuSize(player, payload) then
					log(string.format("%s set menu size %s.", player.Name, payload))
				end
			end))
	end

	-- The guide's step 7 (see THE GUIDE'S TRAVEL STEP above Init).
	if unhookTravel then
		unhookTravel()
	end
	unhookTravel = PlotService.OnTeleportedHome(function(player: Player)
		PlayerDataService.RecordTutorial(player, "travel")
	end)

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
				if entry.dirty and entry.persistent and not entry.leaving
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
