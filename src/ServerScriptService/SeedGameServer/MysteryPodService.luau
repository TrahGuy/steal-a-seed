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
-- (their card reels), the world reveal follows ReelSeconds later.
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
--==============================================================================
function MysteryPodService.Grant(player: any, profile: any): boolean
	local shell = MysteryPodService.ShellId()
	if not shell then
		return false
	end
	local entry = EnchantedMistData.pickCreature(Hooks.random())
	local creature = entry and Hooks.species(entry.Id)
	if not creature then
		-- An outcome the game cannot make is never saved.
		return false
	end
	local size: number? = if EnchantedMistData.isSized(entry.Rarity)
		then EnchantedMistData.pickSize(Hooks.random())
		else nil
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
	return true
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

-- The owner's card reels: the saved creature, then (sized) the saved size.
function MysteryPodService.TellHatch(player: any, outcome: Outcome, token: number)
	Hooks.tell(player, {
		phase = "hatch",
		token = token,
		species = outcome.species.Id,
		rarity = outcome.species.Rarity,
		size = outcome.size,
		seconds = SHELL.ReelSeconds,
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
