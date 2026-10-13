--!strict
--==============================================================================
-- Steal a Seed :: PassService
--
-- Game Pass entitlements. Who owns what, and what that is worth.
--
--==============================================================================
-- WHY THIS IS NOT StoreService
--
-- StoreService sells Developer Products. A product is bought over and over, it
-- arrives as a RECEIPT, and the hard part is making sure a receipt Roblox
-- re-delivers after a restart pays out exactly once -- which is why it keeps a
-- save-backed ledger.
--
-- A Game Pass has none of that shape. It is bought once, it is permanent, and
-- Roblox stores the fact for us. There is no receipt to reconcile and nothing
-- to write to a profile: the right question is "does this account own it", and
-- the answer lives on Roblox's side of the wire.
--
-- Putting the two in one file would mean one file with two entirely different
-- correctness problems in it. The ledger belongs to products; this belongs
-- here.
--
--==============================================================================
-- OWNERSHIP OF THE REAL PASS IS NEVER SAVED
--
-- Deliberately no ProfileSchema field for it. If a pass were mirrored into the save,
-- there would be two answers to "do they own it" -- ours and Roblox's -- and
-- they would drift the first time a refund, a chargeback or a failed save
-- happened. Roblox is the record; this service caches it for a session and
-- throws the cache away on leave.
--
-- The cost of that is one web call per pass per join, which is why the result
-- is cached rather than asked per payout tick.
--
--==============================================================================
-- A GIFTED PASS IS SAVED, BECAUSE NOBODY ELSE HAS IT (2026-10-13, backlog
-- item 6)
--
-- A pass bought for another player is a Developer Product (PassGiftService):
-- Roblox records the purchase, never a pass. So the receipt's grant writes a
-- row on the recipient's profile (ProfileSchema.GiftedPasses), and that row is
-- the only record there is. Every answer here counts "owns the real pass OR
-- has a gifted row" -- read off the profile on each ask, so nothing can drift
-- from it -- and a row is never taken away.
--==============================================================================

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

-- Only for the gifted rows on a profile (A GIFTED PASS IS SAVED, above).
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local PassService = {}
--==============================================================================
-- Before EconomyService (55), which asks this what to multiply the faucet by.
-- Nothing here needs a profile, so it can sit well ahead of the services that
-- do -- what matters is that ownership is known before the first payout tick.
--==============================================================================
PassService.Priority = 22

local STORE = GameConfig.Store
local ATTRIBUTE = GameConfig.Pass.MultiplierAttribute
local BAG_ATTRIBUTE = GameConfig.Pass.BagSlotsAttribute
local VIP_ATTRIBUTE = GameConfig.Pass.VipAttribute
local OWNED_ATTRIBUTE = GameConfig.Pass.OwnedAttribute

--==============================================================================
-- A SLOW RE-ASK, FOR THE PURCHASE WE ARE NOT TOLD ABOUT
--
-- PromptGamePassPurchaseFinished fires for a prompt raised INSIDE this
-- experience. It does not fire when somebody buys the pass from the Roblox
-- website in another tab while sitting in the game, and that player would
-- otherwise earn the base rate until they rejoined.
--
-- So non-owners are re-asked on a slow timer. Owners are never re-asked: a pass
-- is permanent, so the only transition this has to catch is false -> true.
--==============================================================================
local RECHECK_SECONDS = 90

--==============================================================================
-- A FAILED ANSWER IS ASKED AGAIN SOON (2026-10-12, item 9)
--
-- A check that failed -- the web call errored or timed out -- is asked again
-- after RETRY_FAILED_SECONDS, not at the slow re-ask's 90, so an owner whose
-- join check failed gets their pass back in seconds. Meanwhile nothing is
-- taken from anybody: a cached "owned" is never cleared by a failure (below),
-- and a Bag over the base room only stops taking more (CarryService: a limit
-- stops a row being added, never takes one off).
--==============================================================================
local RETRY_FAILED_SECONDS = 15
-- Players with a retry already waiting, so failures never stack them.
local retrying: { [Player]: boolean } = {}

-- key -> the Store item that defines it
local passes: { [string]: any } = {}
-- player -> key -> owned
local owned: { [Player]: { [string]: boolean } } = {}

local running = false
local serviceConnections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/PassService] " .. message)
end

--==============================================================================
-- WHAT PASSES EXIST
--==============================================================================
local function indexPasses(): (number, number)
	table.clear(passes)
	local live, pending = 0, 0
	local byId: { [number]: any } = {}
	for _, item in ipairs(STORE.Items.Passes or {}) do
		passes[tostring(item.key)] = item
		local id = tonumber(item.pass) or 0
		if id > 0 then
			--==================================================================
			-- The same trap StoreService guards on product ids: two rows sharing
			-- an id means one was pasted over the other, and a player who buys
			-- one is granted whichever this loop reached last.
			--==================================================================
			if byId[id] then
				warn(string.format(
					"[Seed/PassService] DUPLICATE game pass id %d on %q and %q. "
					.. "One of them is wrong; neither is safe to sell.",
					id, byId[id].key, item.key))
			end
			byId[id] = item
			live += 1
		else
			pending += 1
		end
	end
	return live, pending
end

--==============================================================================
-- WHAT ONE PLAYER'S PASSES ARE WORTH
--
-- A product over everything they own, so two cash passes would stack rather
-- than the larger one silently winning. There is one pass today and this costs
-- nothing, but the alternative is a rule that only reveals itself as a bug the
-- day a second one ships.
--
-- WHAT A SET OF OWNED PASSES IS WORTH (2026-10-12, item 9: pure, for the specs)
--
-- Over the rows of the passes owned: the cash multiplier (a product, as above),
-- the Bag's extra plant room (`bagSlots`, a sum), a pod's wait factor
-- (`hatchFactor`, a product of factors under 1) and whether any makes a VIP.
--==============================================================================
export type Benefits = { multiplier: number, bagSlots: number, hatchFactor: number, vip: boolean }

function PassService.benefits(rows: { any }): Benefits
	local out: Benefits = { multiplier = 1, bagSlots = 0, hatchFactor = 1, vip = false }
	for _, item in ipairs(rows) do
		local mul = tonumber(item.multiplier)
		if mul and mul > 0 then
			out.multiplier *= mul
		end
		local slots = tonumber(item.bagSlots)
		if slots and slots > 0 then
			out.bagSlots += math.floor(slots)
		end
		local factor = tonumber(item.hatchFactor)
		if factor and factor > 0 and factor < 1 then
			out.hatchFactor *= factor
		end
		if item.vip == true then
			out.vip = true
		end
	end
	return out
end

-- The passes this player was gifted, by key (A GIFTED PASS IS SAVED): the
-- profile's own rows, so empty until it has loaded.
local function giftedKeys(player: Player): { [string]: boolean }
	local out: { [string]: boolean } = {}
	local profile = PlayerDataService.Get(player) :: any
	local rows = if profile then profile.GiftedPasses else nil
	if type(rows) == "table" then
		for _, row in ipairs(rows) do
			if type(row) == "table" and type(row.Pass) == "string" then
				out[row.Pass] = true
			end
		end
	end
	return out
end

-- Every pass this player has -- the real one or a gift -- by key. A key this
-- build does not sell is left out, so it is worth nothing.
local function ownedKeys(player: Player): { [string]: boolean }
	local out = giftedKeys(player)
	for key in pairs(out) do
		if not passes[key] then
			out[key] = nil
		end
	end
	local mine = owned[player]
	if mine then
		for key, isOwned in pairs(mine) do
			if isOwned and passes[key] then
				out[key] = true
			end
		end
	end
	return out
end

local function benefitsOf(player: Player): Benefits
	local rows = {}
	for key in pairs(ownedKeys(player)) do
		table.insert(rows, passes[key])
	end
	return PassService.benefits(rows)
end

local function multiplierFor(player: Player): number
	return benefitsOf(player).multiplier
end

--==============================================================================
-- THE ATTRIBUTE IS FOR THE CLIENT'S EYES, NOT FOR THE PAYOUT
--
-- EconomyService asks CashMultiplier() directly and never reads this. The
-- attribute exists so the garden panel and the +$N pops can show the number the
-- player is actually being paid instead of half of it.
--
-- A client can overwrite its own copy locally. That changes what their own HUD
-- prints and nothing else -- the server never reads it back, and the faucet is
-- computed from `owned`, which only this file writes, and the profile's gifted
-- rows, which only PassGiftService writes.
--==============================================================================
local function publish(player: Player)
	if player.Parent then
		local worth = benefitsOf(player)
		player:SetAttribute(ATTRIBUTE, worth.multiplier)
		-- The item 9 passes (2026-10-12): the Bag's plant room and the VIP flag,
		-- for the HUD and VipChat; VipService hears Changed.
		player:SetAttribute(BAG_ATTRIBUTE, GameConfig.Save.MaxHeld + worth.bagSlots)
		player:SetAttribute(VIP_ATTRIBUTE, worth.vip)
		-- Every pass they have, real or gifted (2026-10-13): the Shop's OWNED.
		local keys = {}
		for key in pairs(ownedKeys(player)) do
			table.insert(keys, key)
		end
		table.sort(keys)
		player:SetAttribute(OWNED_ATTRIBUTE, if #keys > 0 then table.concat(keys, ",") else nil)
		PassService.Changed:Fire(player)
	end
end

--==============================================================================
-- ASKING ROBLOX
--
-- pcall because UserOwnsGamePassAsync is a web call and web calls fail. A
-- failure leaves the cached answer alone rather than clearing it: losing a
-- connection must never take a pass away from somebody who paid for it.
--
-- An id of 0 is never asked about. The call throws on a bad id, and "the owner
-- has not made the pass yet" is not an error worth a stack trace every 90
-- seconds.
--==============================================================================
local function askOne(player: Player, key: string, item: any): boolean?
	local id = tonumber(item.pass) or 0
	if id <= 0 then
		return false
	end
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
	end)
	if not ok then
		warn(string.format("[Seed/PassService] could not check %q for %s: %s",
			key, player.Name, tostring(result)))
		return nil
	end
	return result == true
end

--==============================================================================
-- Only the passes they do not already own, because a pass is permanent and a
-- true can never go back to false. `force` re-asks everything, for a join.
--==============================================================================
local function refresh(player: Player, force: boolean?)
	local mine = owned[player]
	if not mine then
		return
	end
	local changed = false
	local failed = false
	for key, item in pairs(passes) do
		if force or not mine[key] then
			local answer = askOne(player, key, item)
			-- They may have left while the call was in flight.
			if owned[player] ~= mine then
				return
			end
			if answer == nil then
				failed = true
			end
			if answer ~= nil and answer ~= mine[key] then
				mine[key] = answer
				changed = true
				if answer then
					log(string.format("%s owns %q", player.Name, key))
				end
			end
		end
	end
	if changed or force then
		publish(player)
	end
	if failed and not retrying[player] then
		retrying[player] = true
		task.delay(RETRY_FAILED_SECONDS, function()
			retrying[player] = nil
			if owned[player] == mine then
				refresh(player, false)
			end
		end)
	end
end

-- A GIFTED PASS ARRIVES WITH THE PROFILE (2026-10-13): the save loads seconds
-- after the join, and nothing else tells this file, so it looks every
-- PROFILE_POLL seconds -- up to PROFILE_WAIT -- and publishes once it is there.
local PROFILE_POLL = 0.5
local PROFILE_WAIT = 300

local function publishWithProfile(player: Player, mine: { [string]: boolean })
	local waited = 0
	while owned[player] == mine and waited < PROFILE_WAIT do
		if PlayerDataService.Get(player) then
			publish(player)
			return
		end
		task.wait(PROFILE_POLL)
		waited += PROFILE_POLL
	end
end

local function remember(player: Player)
	local mine = {}
	owned[player] = mine
	-- Published before the first web call so the client never reads nil, and so
	-- a player whose check is still in flight shows the base rate rather than a
	-- blank. It is corrected the moment the answer lands.
	publish(player)
	task.spawn(refresh, player, true)
	task.spawn(publishWithProfile, player, mine)
end

local function forget(player: Player)
	owned[player] = nil
	retrying[player] = nil
end

--==============================================================================
-- THE PUBLIC ANSWERS
--==============================================================================
-- The real pass or a gift of it (2026-10-13).
function PassService.Owns(player: Player, key: string): boolean
	return ownedKeys(player)[key] == true
end

--==============================================================================
-- THE GIFTS' QUESTIONS (2026-10-13, backlog item 6; PassGiftService)
--==============================================================================
-- A pass's row in Store.Items.Passes, or nil.
function PassService.Row(key: string): any
	return passes[key]
end

-- Whether `player` has the pass `key`, asking Roblox again first when the
-- cache says no -- a join check that failed, or a pass bought on the website a
-- moment ago -- so a gift is refused BEFORE its prompt. Yields; a failed call
-- leaves the cached answer.
function PassService.CheckOwns(player: Player, key: string): boolean
	if PassService.Owns(player, key) then
		return true
	end
	local item = passes[key]
	local mine = owned[player]
	if not (item and mine) then
		return false
	end
	local answer = askOne(player, key, item)
	if answer and owned[player] == mine and not mine[key] then
		mine[key] = true
		publish(player)
		log(string.format("%s owns %q", player.Name, key))
	end
	return PassService.Owns(player, key)
end

-- After a gifted row lands: the attributes, and VipService's Changed (publish
-- skips a player who has gone).
function PassService.Refresh(player: Player)
	publish(player)
end

--==============================================================================
-- Used by EconomyService on the plant faucet and NOWHERE ELSE. Bag sales, Robux
-- cash packs, plot and mill refunds and debug grants all reach AddCash by other
-- routes and are all meant to be unaffected -- doubling a refund would pay a
-- player more to undo a purchase than the purchase cost.
--
-- 1 for a player still being checked, so the failure direction is "paid the
-- base rate for a moment", never "paid double by accident".
--==============================================================================
function PassService.CashMultiplier(player: Player): number
	return multiplierFor(player)
end

--==============================================================================
-- THE ITEM 9 PASSES (2026-10-12): 0 / 1 / false for a player still being
-- checked, so the failure direction is the base game, never a free benefit.
--==============================================================================
-- Plant room in the Bag on top of Save.MaxHeld (+12 Bag Slots).
function PassService.BagBonus(player: Player): number
	return benefitsOf(player).bagSlots
end

-- A pod's wait times this (Faster Hatch: 0.75).
function PassService.HatchFactor(player: Player): number
	return benefitsOf(player).hatchFactor
end

function PassService.IsVip(player: Player): boolean
	return benefitsOf(player).vip
end

-- A pod's wait in seconds for `factor`: the species' own
-- (SeedData.GrowSecondsFor) times it -- never a Mysterious Pod's, which keeps
-- its fixed wait. Pure, for the specs.
function PassService.growSecondsWith(factor: number, species: any, tier: number?): number
	local seconds = SeedData.GrowSecondsFor(species, tier)
	if type(species) == "table" and species.Mystery == true then
		return seconds
	end
	return seconds * factor
end

-- The wait a pod of this player's is stamped with, where a deadline is
-- stamped (a bank, a gift, a planting).
function PassService.GrowSeconds(player: Player, species: any, tier: number?): number
	return PassService.growSecondsWith(PassService.HatchFactor(player), species, tier)
end

-- After a player's passes are published (known, or changed): VipService
-- dresses or undresses their name.
PassService.Changed = Instance.new("BindableEvent")

--==============================================================================
-- A TEST DOOR, BECAUSE THE PASS DOES NOT EXIST YET
--
-- The x2 Money pass has an id of 0 until the owner creates it in the Creator
-- Dashboard, so until then NOBODY can own it and the multiplier can never be
-- anything but 1. That would leave the whole entitlement path -- the faucet
-- multiply, the attribute, the three client readouts -- shipped and never once
-- executed.
--
-- This lets DebugService pretend. It is safe for the same reason every other
-- DebugService action is: that service answers the place owner in Studio and
-- nobody else, and it is the only caller. It writes the same cache a real
-- ownership answer writes, so what gets tested is the real path and not a
-- parallel one.
--
-- It grants nothing durable. Ownership is never saved, so this dies with the
-- session -- and a real join re-asks Roblox and overwrites it.
--==============================================================================
function PassService.DebugSetOwned(player: Player, key: string, value: boolean): boolean
	local mine = owned[player]
	if not mine or not passes[key] then
		return false
	end
	mine[key] = value
	publish(player)
	return true
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function PassService.Init()
	indexPasses()
end

function PassService.Start()
	if running then
		return
	end
	running = true

	local live, pending = indexPasses()

	table.insert(serviceConnections, Players.PlayerAdded:Connect(remember))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(forget))

	--==========================================================================
	-- Studio starts services with the player already in, so PlayerAdded has
	-- been and gone. Every service in this project that tracks players does
	-- this, for the same reason.
	--==========================================================================
	for _, player in ipairs(Players:GetPlayers()) do
		remember(player)
	end

	--==========================================================================
	-- THE PROMPT CLOSING IS THE FAST PATH
	--
	-- `wasPurchased` is not trusted on its own -- it is re-asked. The prompt
	-- says what the player did, and UserOwnsGamePassAsync says what they own,
	-- and only the second one is the thing the faucet should key off.
	--==========================================================================
	table.insert(serviceConnections, MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, passId: number, wasPurchased: boolean)
			if not wasPurchased then
				return
			end
			for key, item in pairs(passes) do
				if (tonumber(item.pass) or 0) == passId then
					task.spawn(function()
						local answer = askOne(player, key, item)
						local mine = owned[player]
						if answer and mine then
							mine[key] = true
							publish(player)
							log(string.format("%s bought %q in-game", player.Name, key))
						end
					end)
					return
				end
			end
		end))

	--==========================================================================
	-- The slow re-ask. Skipped entirely while no pass has a real id, so a beta
	-- with everything unset makes no web calls at all.
	--==========================================================================
	if live > 0 then
		task.spawn(function()
			while running do
				task.wait(RECHECK_SECONDS)
				for _, player in ipairs(Players:GetPlayers()) do
					task.spawn(refresh, player, false)
				end
			end
		end)
	end

	if live == 0 then
		log(string.format(
			"Ready. %d pass(es) defined and every one has an id of 0, so nobody owns "
			.. "anything and no ownership calls are made. Create the Game Pass and "
			.. "fill its id into GameConfig.Store.Items.Passes.", pending))
	else
		log(string.format(
			"Ready. %d live pass(es), %d pending; ownership re-checked every %ds for "
			.. "players who do not own one yet.", live, pending, RECHECK_SECONDS))
	end
end

function PassService.Stop()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(owned)
end

function PassService.Snapshot(): string
	local rows = { "PassService:" }
	for key, item in pairs(passes) do
		local id = tonumber(item.pass) or 0
		table.insert(rows, string.format("  %-10s id=%s multiplier=%s",
			key,
			if id > 0 then tostring(id) else "-",
			tostring(tonumber(item.multiplier) or 1)))
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local parts = {}
		for key in pairs(passes) do
			table.insert(parts, string.format("%s=%s", key, tostring(PassService.Owns(player, key))))
		end
		table.insert(rows, string.format("  %-16s x%.2f  %s",
			player.Name, PassService.CashMultiplier(player), table.concat(parts, " ")))
	end
	return table.concat(rows, "\n")
end

return PassService
