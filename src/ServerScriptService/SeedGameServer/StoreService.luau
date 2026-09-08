--!strict
--==============================================================================
-- Steal a Seed :: StoreService
--
-- The Robux side of the shop. Four shelves are drawn by ShopUI; this is the one
-- place that decides whether a purchase actually happened and what it gave.
--
--==============================================================================
-- THE CLIENT PROMPTS. IT DOES NOT GRANT.
--
-- ShopUI calls MarketplaceService:PromptProductPurchase with a product id and
-- that is the whole of its involvement. The reward is worked out HERE, from the
-- ProductId Roblox hands back with the receipt -- never from anything the client
-- said, because the client is where the money is not.
--
-- There is no remote in this file. A purchase arrives as a receipt from Roblox,
-- not as a message from a player.
--
--==============================================================================
-- ONE ProcessReceipt, AND IT MUST BE THIS ONE
--
-- MarketplaceService.ProcessReceipt is a single callback for the whole
-- experience: assigning it twice silently replaces the first. So it is assigned
-- exactly once, here, and nothing else in this project may take it.
--
--==============================================================================
-- GRANTED ONCE, HOWEVER MANY TIMES IT ARRIVES
--
-- Roblox re-delivers a receipt until it is told PurchaseGranted -- across a
-- server restart, a rejoin, and days of downtime. Anything less than a record
-- that survives the SAVE will grant twice, and this is the one place in the
-- project where a double-grant costs somebody real money.
--
-- So the honoured PurchaseIds live on the profile (ProfileSchema.Receipts), the
-- check happens before the grant, and the profile is written before the receipt
-- is acknowledged. The order matters and it is deliberate:
--
--   1. already in the ledger?          -> PurchaseGranted, grant nothing
--   2. profile not loaded yet?         -> NotProcessedYet, Roblox will retry
--   3. grant, append the id, SAVE
--   4. saved?                          -> PurchaseGranted
--      not saved?                      -> NotProcessedYet
--
-- Step 4 is the one that is easy to get wrong. Acknowledging a receipt whose
-- grant has not reached the DataStore means a crash in the next second loses the
-- item AND the retry. Better to be re-delivered and refuse at step 1.
--==============================================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))

local StoreService = {}
-- After PlayerDataService (20) and CarryService (45): a receipt can land in the
-- first second of the server's life and both have to be able to answer.
StoreService.Priority = 66

local STORE = GameConfig.Store
local SAVE = GameConfig.Save

local function log(message: string)
	print("[Seed/StoreService] " .. message)
end

--==============================================================================
-- PRODUCT ID -> WHAT IT GIVES
--
-- Built once from the manifest and keyed on the id, because that is what a
-- receipt carries. Entries with product = 0 are not in it at all: an
-- uncreated product cannot be bought, so it cannot be granted either.
--==============================================================================
local byProduct: { [number]: any } = {}

local function indexProducts(): (number, number)
	table.clear(byProduct)
	local live, pending = 0, 0
	for _, section in ipairs(STORE.Sections) do
		for _, item in ipairs(STORE.Items[section.id] or {}) do
			local id = tonumber(item.product) or 0
			if id > 0 then
				--==============================================================
				-- A DUPLICATE ID IS THE ONE MISTAKE THAT SELLS THE WRONG THING
				--
				-- Two entries sharing an id means one of them was pasted over
				-- the other, and the player is charged for the tile they clicked
				-- and given whichever of the two this loop reached last. Loud at
				-- boot rather than quiet at the till.
				--==============================================================
				if byProduct[id] then
					warn(string.format(
						"[Seed/StoreService] DUPLICATE product id %d on %q and %q. "
						.. "One of them is wrong; neither is safe to sell.",
						id, byProduct[id].key, item.key))
				end
				byProduct[id] = item
				live += 1
			else
				pending += 1
			end
		end
	end
	return live, pending
end

--==============================================================================
-- WHAT AN ITEM ACTUALLY DOES
--
-- Every branch returns whether the grant LANDED. A false here means the receipt
-- is not acknowledged and Roblox tries again, which is the right answer for a
-- player who is mid-respawn with no backpack to put a pod in.
--==============================================================================
local function grant(player: Player, item: any): boolean
	if item.kind == "speed" then
		return PlayerDataService.AddSpeed(player, item.amount or 0) ~= nil
	elseif item.kind == "cash" then
		return PlayerDataService.AddCash(player, item.amount or 0) ~= nil
	elseif item.kind == "pod" then
		--======================================================================
		-- FIXED CONTENTS, NAMED BY THE PRODUCT
		--
		-- The species and the tier come off the manifest entry, not off a roll.
		-- See the note in GameConfig.Store: a rolled pod would be a paid random
		-- item and a different compliance position entirely.
		--======================================================================
		if not SeedData.Get(tostring(item.species)) then
			warn(string.format("[Seed/StoreService] %q names an unknown species %q",
				item.key, tostring(item.species)))
			return false
		end
		return CarryService.GivePod(player, item.species, item.tier or 1)
	end
	warn(string.format("[Seed/StoreService] %q has no grant for kind %q",
		item.key, tostring(item.kind)))
	return false
end

--==============================================================================
-- THE LEDGER
--==============================================================================
local function alreadyHonoured(profile: any, purchaseId: string): boolean
	for _, id in ipairs(profile.Receipts or {}) do
		if id == purchaseId then
			return true
		end
	end
	return false
end

local function remember(profile: any, purchaseId: string)
	local list = profile.Receipts
	table.insert(list, purchaseId)
	-- Oldest out. The cap only has to outlive a retry -- see Save.MaxReceipts.
	while #list > SAVE.MaxReceipts do
		table.remove(list, 1)
	end
end

--==============================================================================
-- THE RECEIPT
--==============================================================================
local function processReceipt(info: any): Enum.ProductPurchaseDecision
	local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
	local RETRY = Enum.ProductPurchaseDecision.NotProcessedYet

	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		-- Gone. Roblox re-delivers when they come back, and the ledger check
		-- above will still be the thing that stops a double grant.
		return RETRY
	end

	local profile = PlayerDataService.Get(player)
	if not profile then
		-- Their save has not arrived. Granting into a profile that is about to
		-- be replaced by the loaded one is how a purchase disappears.
		return RETRY
	end

	local purchaseId = tostring(info.PurchaseId)
	if alreadyHonoured(profile, purchaseId) then
		-- A retry of something already given. Acknowledge it so Roblox stops.
		return GRANTED
	end

	local item = byProduct[info.ProductId]
	if not item then
		--======================================================================
		-- A PRODUCT THIS BUILD DOES NOT KNOW
		--
		-- Almost always a product created in the dashboard but not yet added to
		-- GameConfig.Store. NOT granted and NOT acknowledged: the player is not
		-- charged twice, and once the manifest catches up the retry pays out.
		--======================================================================
		warn(string.format(
			"[Seed/StoreService] receipt for unknown product %s (%s). "
			.. "Add it to GameConfig.Store before this can be honoured.",
			tostring(info.ProductId), player.Name))
		return RETRY
	end

	if not grant(player, item) then
		warn(string.format("[Seed/StoreService] %s: %q could not be granted now; will retry",
			player.Name, item.key))
		return RETRY
	end

	remember(profile, purchaseId)

	--==========================================================================
	-- ACKNOWLEDGED ONLY ONCE IT IS ON DISK
	--
	-- If the write fails, the grant has happened in memory but nothing outside
	-- this server knows. Refusing to acknowledge means Roblox re-delivers, and
	-- the ledger entry -- which did not save either -- will not stop it. The
	-- player gets the item; that is the right way round to be wrong.
	--==========================================================================
	if not PlayerDataService.Save(player) then
		warn(string.format("[Seed/StoreService] %s: %q granted but not saved; not acknowledging",
			player.Name, item.key))
		return RETRY
	end

	log(string.format("%s bought %q (product %s)", player.Name, item.key,
		tostring(info.ProductId)))
	return GRANTED
end

function StoreService.Init()
	indexProducts()
end

function StoreService.Start()
	local live, pending = indexProducts()

	--==========================================================================
	-- TAKEN ONCE, AND SAID OUT LOUD
	--
	-- If another script ever assigns this too, whichever runs last wins and the
	-- other one's purchases stop paying out with no error anywhere. The log line
	-- is what makes that findable.
	--==========================================================================
	MarketplaceService.ProcessReceipt = processReceipt

	if live == 0 then
		log(string.format(
			"Ready, but NOTHING IS FOR SALE: %d product(s) in the manifest and every "
			.. "one has an id of 0. Create them in the Creator Dashboard and fill the "
			.. "ids into GameConfig.Store.", pending))
	else
		log(string.format("Ready. %d product(s) live, %d still waiting for an id.",
			live, pending))
	end
end

--==============================================================================
-- WHAT THE CLIENT IS ALLOWED TO ASK
--
-- Nothing. This is here so the shape of the file matches the others and so the
-- debug console can see the shelf.
--==============================================================================
function StoreService.Snapshot(): string
	local live, pending = indexProducts()
	local rows = { string.format("StoreService: %d live, %d pending", live, pending) }
	for _, section in ipairs(STORE.Sections) do
		local items = STORE.Items[section.id] or {}
		local parts = {}
		for _, item in ipairs(items) do
			table.insert(parts, string.format("%s=%s", item.key,
				if (tonumber(item.product) or 0) > 0 then tostring(item.product) else "-"))
		end
		rows[#rows + 1] = string.format("  %-12s %s", section.id,
			if #parts == 0 then "(empty)" else table.concat(parts, " "))
	end
	return table.concat(rows, "\n")
end

return StoreService
