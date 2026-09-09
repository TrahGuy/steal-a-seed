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
-- OWNERSHIP IS NEVER SAVED
--
-- Deliberately no ProfileSchema field. If a pass were mirrored into the save,
-- there would be two answers to "do they own it" -- ours and Roblox's -- and
-- they would drift the first time a refund, a chargeback or a failed save
-- happened. Roblox is the record; this service caches it for a session and
-- throws the cache away on leave.
--
-- The cost of that is one web call per pass per join, which is why the result
-- is cached rather than asked per payout tick.
--==============================================================================

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local PassService = {}
--==============================================================================
-- Before EconomyService (55), which asks this what to multiply the faucet by.
-- Nothing here needs a profile, so it can sit well ahead of the services that
-- do -- what matters is that ownership is known before the first payout tick.
--==============================================================================
PassService.Priority = 22

local STORE = GameConfig.Store
local ATTRIBUTE = GameConfig.Pass.MultiplierAttribute

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
--==============================================================================
local function multiplierFor(player: Player): number
	local mine = owned[player]
	if not mine then
		return 1
	end
	local n = 1
	for key, isOwned in pairs(mine) do
		if isOwned then
			local item = passes[key]
			local mul = item and tonumber(item.multiplier)
			if mul and mul > 0 then
				n *= mul
			end
		end
	end
	return n
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
-- computed from `owned`, which only this file writes.
--==============================================================================
local function publish(player: Player)
	if player.Parent then
		player:SetAttribute(ATTRIBUTE, multiplierFor(player))
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
	for key, item in pairs(passes) do
		if force or not mine[key] then
			local answer = askOne(player, key, item)
			-- They may have left while the call was in flight.
			if owned[player] ~= mine then
				return
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
end

local function remember(player: Player)
	owned[player] = {}
	-- Published before the first web call so the client never reads nil, and so
	-- a player whose check is still in flight shows the base rate rather than a
	-- blank. It is corrected the moment the answer lands.
	publish(player)
	task.spawn(refresh, player, true)
end

local function forget(player: Player)
	owned[player] = nil
end

--==============================================================================
-- THE PUBLIC ANSWERS
--==============================================================================
function PassService.Owns(player: Player, key: string): boolean
	local mine = owned[player]
	return (mine ~= nil) and mine[key] == true
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
