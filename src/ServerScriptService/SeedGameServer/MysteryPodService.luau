--!strict
--==============================================================================
-- Steal a Seed :: MysteryPodService (2026-10-11, Enchanted Mist stage 4)
--
-- THE MYSTERIOUS POD (KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-PROMPT.md §10-11).
--
-- GRANT (Mosskeeper's Give all, inside its one profile change, never
-- yielding): the server picks the creature (EnchantedMistData.pickCreature)
-- and, for Legendary to Divine only, the size (pickSize) -- ONCE -- and gives
-- one generic SHELL pod (EnchantedMistData.Shell.Id) into the Bag. The
-- outcome is saved under the shell's Item id in Profile.MysteryPods, with the
-- pool and size versions and the 30-second ready time, in that same change as
-- the berries and the progress: a retry or a disconnect can neither double nor
-- lose it. Nothing names the outcome before the hatch: the row and the Tool
-- carry the shell's id, and the profile a client sees never holds
-- MysteryPods (ProfileSchema.ClientView).
--
-- HATCH (PlantService's Bag hatch, one saved Item): the shell resolves to its
-- outcome -- the saved creature, at the saved size, or a Secret's own -- and
-- the record is consumed in the same no-yield step that takes the shell off
-- the Bag, so it hatches exactly once. The owner of the pod is told first
-- (their card draw), the world reveal follows at the draw's end (Reserve).
--
-- OFF until bound: no shell id, or a shell or creature SeedData does not
-- know, and no pod is granted (MosskeeperService refuses the whole delivery).
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))

local MysteryPodService = {}
-- After MosskeeperService (77), whose grant hook this fills.
MysteryPodService.Priority = 78

local SHELL = EnchantedMistData.Shell
local POOL = EnchantedMistData.Pool
local SIZES = EnchantedMistData.Sizes

local function log(message: string)
	print("[Seed/MysteryPodService] " .. message)
end

--==============================================================================
-- SPEC-REPLACEABLE HOOKS
--==============================================================================
local rng = Random.new()

MysteryPodService.Hooks = {
	now = function(): number
		return os.time()
	end,
	random = function(): number
		return rng:NextNumber()
	end,
	shellId = function(): string?
		return SHELL.Id
	end,
	species = function(id: string): any
		return SeedData.Get(id)
	end,
	-- One shell pod into the Bag: (given, its Item id). Never yields.
	giveShell = function(player: any, shellId: string): (boolean, string?)
		return CarryService.GivePod(player, shellId, 1)
	end,
	profile = function(player: any): any
		return PlayerDataService.Get(player)
	end,
	-- A save soon after a grant or a hatch (the precedent: InviteService).
	saveSoon = function(player: any)
		task.spawn(PlayerDataService.Save, player)
	end,
	-- To the pod's owner: their card reels. Start points it at GameEvent.
	tell = function(_player: any, _payload: { [string]: any }) end,
}
local Hooks = MysteryPodService.Hooks

-- The shell's species id, when it is bound and SeedData knows it.
function MysteryPodService.ShellId(): string?
	local id = Hooks.shellId()
	if type(id) == "string" and Hooks.species(id) ~= nil then
		return id
	end
	return nil
end

-- Whether a delivery can earn a pod now: the shell bound, and every creature
-- the pool can pick a real species (none is ever substituted).
function MysteryPodService.CanGrant(): boolean
	if not MysteryPodService.ShellId() then
		return false
	end
	for _, entry in ipairs(POOL.Entries) do
		if Hooks.species(entry.Id) == nil then
			return false
		end
	end
	return true
end

function MysteryPodService.IsShell(id: any): boolean
	local shell = MysteryPodService.ShellId()
	return shell ~= nil and id == shell
end

--==============================================================================
-- THE GRANT: inside the delivery's own profile change; never yields.
--
-- `choice` (2026-10-12, an admin's GIVE A MYSTERIOUS POD): a pool creature by
-- id -- and, for a sized rarity, its size -- in place of the roll; a sized
-- creature without one rolls its size as a delivery's does. A creature the
-- pool does not hold, a size out of range or a size asked for a Secret is
-- never granted. Without a choice the grant rolls everything, as before.
--==============================================================================
export type Choice = { species: string, size: number? }

-- The pool's entry for a creature id, or nil.
function MysteryPodService.PoolEntry(id: any): any
	for _, entry in ipairs(POOL.Entries) do
		if entry.Id == id then
			return entry
		end
	end
	return nil
end

-- Answers whether it granted, and the shell's Item id (its record's key).
function MysteryPodService.Grant(player: any, profile: any, choice: Choice?): (boolean, string?)
	local shell = MysteryPodService.ShellId()
	if not shell then
		return false
	end
	local entry = if choice then MysteryPodService.PoolEntry(choice.species)
		else EnchantedMistData.pickCreature(Hooks.random())
	local creature = entry and Hooks.species(entry.Id)
	if not creature then
		-- An outcome the game cannot make is never saved.
		return false
	end
	local size: number? = nil
	local asked = if choice then choice.size else nil
	if EnchantedMistData.isSized(entry.Rarity) then
		if asked ~= nil then
			if type(asked) ~= "number" or asked ~= math.floor(asked) or asked < 1 or asked > SeedData.TierCount then
				return false
			end
			size = asked
		else
			size = EnchantedMistData.pickSize(Hooks.random())
		end
	elseif asked ~= nil then
		-- A Secret keeps its own size: one asked for it is refused, never dropped.
		return false
	end
	local given, item = Hooks.giveShell(player, shell)
	if not given or type(item) ~= "string" then
		return false
	end
	local records = profile.MysteryPods
	if type(records) ~= "table" then
		records = {}
		profile.MysteryPods = records
	end
	records[item] = {
		Species = entry.Id,
		Size = size,
		PoolVersion = POOL.Version,
		SizesVersion = SIZES.Version,
		ReadyAt = Hooks.now() + EnchantedMistData.HatchSeconds,
	}
	log(string.format("%s was given a Mysterious Pod (%s).", tostring(player.Name), item))
	return true, item
end

--==============================================================================
-- MAKE READY NOW (2026-10-12, an admin's: the owner's item 12)
--
-- Every Mysterious Pod `profile` holds a record for, ready at `now` (the
-- grant's own clock, Hooks.now) -- inside the caller's profile change, never
-- yielding. Answers the Item ids whose record was still waiting, and every
-- shell's: the caller moves each one's Bag row too (CarryService.
-- SetPodDeadline), as a shell hatches at the later of the two.
--==============================================================================
function MysteryPodService.MakeReady(profile: any, now: number): ({ string }, { string })
	local records = profile.MysteryPods
	local waiting: { string } = {}
	local items: { string } = {}
	if type(records) ~= "table" then
		return waiting, items
	end
	for item, rec in pairs(records) do
		if type(item) == "string" and type(rec) == "table" then
			table.insert(items, item)
			if (tonumber(rec.ReadyAt) or 0) > now then
				rec.ReadyAt = now
				table.insert(waiting, item)
			end
		end
	end
	table.sort(waiting)
	table.sort(items)
	return waiting, items
end

--==============================================================================
-- THE OUTCOME, AT THE HATCH
--==============================================================================
export type Outcome = { species: any, tier: number, size: number?, readyAt: number }

-- A shell's saved outcome, or nil: the saved creature, the saved size or (a
-- Secret, or any creature that rolls no size) its own fixed one.
function MysteryPodService.Outcome(player: any, item: string): Outcome?
	local profile = Hooks.profile(player)
	local records = profile and profile.MysteryPods
	local rec = if type(records) == "table" then records[item] else nil
	if type(rec) ~= "table" then
		return nil
	end
	local creature = Hooks.species(rec.Species)
	if not creature then
		return nil
	end
	local tier = if rec.Size ~= nil then rec.Size
		elseif SeedData.Unsized(creature) then SeedData.SecretTier
		else 1
	return { species = creature, tier = tier, size = rec.Size, readyAt = tonumber(rec.ReadyAt) or 0 }
end

-- The record spent: in the same no-yield step that takes the shell away.
function MysteryPodService.Consume(player: any, item: string)
	local profile = Hooks.profile(player)
	local records = profile and profile.MysteryPods
	if type(records) == "table" then
		records[item] = nil
	end
end

--==============================================================================
-- EACH PLAYER'S DRAWS, ONE AFTER ANOTHER (2026-10-12, the owner: "sometimes
-- the draw doesn't run, it auto chooses")
--
-- A second pod hatched while a draw ran used to cut that draw short: its
-- creature came out unseen. Now each draw is reserved here, starting when this
-- player's last one ends (or `after` from `now`, whichever is later) and
-- running EnchantedMistData.drawSeconds for its outcome; PlantService brings
-- the world reveal in at the draw's end and the client plays them in turn.
-- `now` is the caller's Workspace:GetServerTimeNow(), the client's clock too.
-- A hatch refused after its reservation gives the slot back (Unreserve).
--==============================================================================
local drawEnds: { [any]: number } = setmetatable({} :: any, { __mode = "k" })
local drawWas: { [any]: { ends: number, was: number? } } = setmetatable({} :: any, { __mode = "k" })

function MysteryPodService.Reserve(player: any, outcome: Outcome, now: number, after: number?): (number, number)
	local sized = outcome.size ~= nil and EnchantedMistData.isSized(tostring(outcome.species.Rarity))
	local seconds = EnchantedMistData.drawSeconds(sized)
	local was = drawEnds[player]
	local startAt = math.max(now + math.max(tonumber(after) or 0, 0), was or -math.huge)
	drawEnds[player] = startAt + seconds
	drawWas[player] = { ends = startAt + seconds, was = was }
	return startAt, seconds
end

function MysteryPodService.Unreserve(player: any, startAt: number, seconds: number)
	local r = drawWas[player]
	if r and r.ends == startAt + seconds and drawEnds[player] == r.ends then
		drawEnds[player] = r.was
		drawWas[player] = nil
	end
end

-- The owner's card draw: the saved creature, then (sized) the saved size, from
-- `startAt` (server clock) for `seconds` (Reserve).
function MysteryPodService.TellHatch(player: any, outcome: Outcome, token: number, startAt: number?, seconds: number?)
	local sized = outcome.size ~= nil and EnchantedMistData.isSized(tostring(outcome.species.Rarity))
	Hooks.tell(player, {
		phase = "hatch",
		token = token,
		species = outcome.species.Id,
		rarity = outcome.species.Rarity,
		size = outcome.size,
		startAt = startAt,
		seconds = seconds or EnchantedMistData.drawSeconds(sized),
	})
	Hooks.saveSoon(player)
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function MysteryPodService.Init() end

function MysteryPodService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if found and found:IsA("RemoteEvent") then
		local channel = found :: RemoteEvent
		Hooks.tell = function(player: any, payload: { [string]: any })
			if player.Parent == Players then
				channel:FireClient(player, EnchantedMistConfig.Mystery.Action, payload)
			end
		end
	end
	-- Stage 3's hook, filled once the shell is bound.
	local Mosskeeper = require(script.Parent:WaitForChild("MosskeeperService")) :: any
	if MysteryPodService.ShellId() then
		Mosskeeper.Hooks.grantPod = MysteryPodService.Grant
		Mosskeeper.Hooks.canGrant = MysteryPodService.CanGrant
		Mosskeeper.Hooks.saveSoon = Hooks.saveSoon
		log("Ready: the Mysterious Pod is granted by the Mosskeeper.")
	else
		log("off (EnchantedMistData.Shell.Id is not bound).")
	end
end

return MysteryPodService
