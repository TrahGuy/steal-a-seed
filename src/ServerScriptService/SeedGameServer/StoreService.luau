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
local WheelData = require(Shared:WaitForChild("WheelData"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))
local PlantService = require(script.Parent:WaitForChild("PlantService"))
local WheelService = require(script.Parent:WaitForChild("WheelService"))

local StoreService = {}
-- After PlayerDataService (20), CarryService (45), PlantService (50) and
-- TreadmillService (60): a receipt can land in the first second of the server's
-- life and all four have to be able to answer.
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
--
-- The shelves AND the products sold in the world (Store.InWorld), read as one
-- list, so the duplicate-id check below sees every id this game sells.
--==============================================================================
local byProduct: { [number]: any } = {}
-- The wheel's spin products while paid spins are switched off: id -> key.
local wheelOff: { [number]: string } = {}

local function allItems(): { any }
	local list = {}
	for _, section in ipairs(STORE.Sections) do
		for _, item in ipairs(STORE.Items[section.id] or {}) do
			table.insert(list, item)
		end
	end
	for _, item in ipairs(STORE.InWorld or {}) do
		table.insert(list, item)
	end
	return list
end

local function indexProducts(): (number, number)
	table.clear(byProduct)
	local live, pending = 0, 0
	for _, item in ipairs(allItems()) do
		--======================================================================
		-- A GAME PASS IS NOT A PRODUCT AND IS NOT COUNTED AS ONE
		--
		-- The pass row has no `product`, so it could never be indexed or
		-- sold from here -- but it WOULD have been tallied as one more
		-- pending product, and the boot line that says how many things are
		-- waiting on an id would then name a number that does not match the
		-- Developer Products the owner has to create. PassService owns it.
		--======================================================================
		if item.pass ~= nil then
			continue
		end
		local id = tonumber(item.product) or 0
		if id > 0 then
			--==================================================================
			-- A DUPLICATE ID IS THE ONE MISTAKE THAT SELLS THE WRONG THING
			--
			-- Two entries sharing an id means one of them was pasted over
			-- the other, and the player is charged for the tile they clicked
			-- and given whichever of the two this loop reached last. Loud at
			-- boot rather than quiet at the till.
			--==================================================================
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
	--==========================================================================
	-- THE REWARD WHEEL'S SPIN PRODUCTS (WheelData, 2026-09-29; 2026-10-01)
	--
	-- Every product a receipt may name: the three packs on sale (1, 5 and 10
	-- spins) AND the two retired ones (+1 Spin, +10 Spins), so a purchase made
	-- before they were disabled is still paid -- once, through the ledger below.
	-- Each its own id and its own quantity: the receipt's ProductId picks the
	-- row and the row says how many, so no two can pay each other's amount. A
	-- spin is a paid random item, so they are indexed only while paid spins are
	-- on (WheelData.paidLive) -- off, no receipt can grant a spin, whatever it
	-- names (KB/HANDOFF.md, the paid-spins entry).
	--
	-- `wheelOff` remembers the ids while they are NOT indexed, for one purpose:
	-- a receipt that names one then is said to be exactly that in the log,
	-- rather than "a product this build does not know".
	--==========================================================================
	table.clear(wheelOff)
	for _, product in ipairs(WheelData.receiptProducts()) do
		if not WheelData.paidLive() then
			wheelOff[product.productId] = product.key
			continue
		end
		if byProduct[product.productId] then
			warn(string.format("[Seed/StoreService] DUPLICATE product id %d on the wheel's %q and %q. "
				.. "One of them is wrong; neither is safe to sell.",
				product.productId, product.key, byProduct[product.productId].key))
		end
		byProduct[product.productId] = {
			key = "wheel:" .. product.key,
			kind = "spins",
			amount = product.spins,
			product = product.productId,
			robux = product.robux,
		}
		live += 1
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
		--======================================================================
		-- THROUGH THE SPEED FAUCET, WHICH IS WHAT MAKES IT RUN FASTER NOW
		--
		-- This used to call PlayerDataService.AddSpeed and stop. The score went
		-- up, but WalkSpeed is CarryService's and only recomputed when something
		-- asks -- the belt, a take, a drop, a respawn -- so a bought pack did
		-- nothing until the player rode a mill or stole a pod. Reported exactly
		-- like that. PayReward is the same one-off grant the Biome Harvest uses:
		-- it adds the score AND asks CarryService to recompute.
		--======================================================================
		return TreadmillService.PayReward(player, item.amount or 0,
			string.format("the %q pack", tostring(item.key)))
	elseif item.kind == "cash" then
		return PlayerDataService.AddCash(player, item.amount or 0) ~= nil
	elseif item.kind == "pod" then
		--======================================================================
		-- FIXED CONTENTS, NAMED BY THE PRODUCT
		--
		-- The species and the tier come off the manifest entry, not off a roll.
		-- See the note in GameConfig.Store: a rolled pod would be a paid random
		-- item and a different compliance position entirely.
		--
		-- GivePod gives only into room, and writes the pod down as it gives it
		-- (2026-09-30). A false -- plant storage full, the row not written, no
		-- backpack -- leaves the receipt open: a paid pod is never acknowledged
		-- for a pod the save does not hold. The pod products are off sale (id
		-- 0, so not indexed above and never granted); a receipt left open
		-- until there is room is the fallback, not a design for selling them.
		--======================================================================
		if not SeedData.Get(tostring(item.species)) then
			warn(string.format("[Seed/StoreService] %q names an unknown species %q",
				item.key, tostring(item.species)))
			return false
		end
		return (CarryService.GivePod(player, item.species, item.tier or 1))
	elseif item.kind == "hatch" then
		--======================================================================
		-- A POD OPENED NOW, NOT A THING HANDED OVER
		--
		-- The receipt does not say which pod, so PlantService works that out
		-- from the press that opened the dialog (see WHICH POD A RECEIPT
		-- HATCHES). With no pod it can open -- none unhatched, no garden in the
		-- world yet, or storage full with no wait left -- the purchase is kept
		-- as a saved Instant Hatch (2026-09-30). False when nothing could be
		-- given or kept -- no Backpack to put the creature in, a profile that
		-- can never be saved -- so the receipt is retried rather than
		-- acknowledged for nothing.
		--======================================================================
		return PlantService.InstantHatch(player)
	elseif item.kind == "spins" then
		--======================================================================
		-- PURCHASED WHEEL SPINS, INTO THEIR OWN BALANCE
		--
		-- Counted apart from earned spins (WheelBought), never against the
		-- daily earning allowance. The spins land here; the prize of a spin is
		-- rolled only when the player spends one, at the wheel. False when the
		-- profile cannot take them or the player may not hold a paid random
		-- item (WheelService asks PolicyService, and fails closed), so the
		-- receipt is not acknowledged.
		--======================================================================
		return WheelService.GrantBought(player, item.amount or 0)
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
local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
local RETRY = Enum.ProductPurchaseDecision.NotProcessedYet

-- Receipts being decided at this moment, by purchase id (see processReceipt).
local deciding: { [string]: boolean } = {}
-- And how many for each player (2026-10-08): a rebirth waits for them, so a
-- cash pack being granted is never wiped by the rebirth that spends the cash.
local decidingFor: { [Player]: number } = {}

-- Whether a receipt of this player's is being decided right now.
function StoreService.Deciding(player: Player): boolean
	return (decidingFor[player] or 0) > 0
end

local function decide(info: any, player: Player, profile: any, purchaseId: string): Enum.ProductPurchaseDecision
	if alreadyHonoured(profile, purchaseId) then
		--======================================================================
		-- A RETRY OF SOMETHING ALREADY GIVEN, ACKNOWLEDGED ONLY ONCE IT IS ON DISK
		--
		-- The ledger entry lives in memory from the moment `remember` runs, so
		-- it is found here whether or not the save below it ever wrote. It used
		-- to answer GRANTED outright, which acknowledged a purchase that was
		-- granted into a temporary profile (DataStores unreachable, every write
		-- refused) or whose save had failed: paid for, gone with the server.
		-- Found in the 2026-09-19 audit. Now the retry is what gets the ledger
		-- written; until that succeeds Roblox keeps re-delivering, and nothing
		-- is granted twice because the entry is already here.
		--======================================================================
		if PlayerDataService.Save(player) then
			return GRANTED
		end
		warn(string.format("[Seed/StoreService] %s: receipt %s granted earlier but still not saved; "
			.. "not acknowledging", player.Name, purchaseId))
		return RETRY
	end

	local item = byProduct[info.ProductId]
	if not item and wheelOff[info.ProductId] then
		--======================================================================
		-- A SPIN PRODUCT, WHILE PAID SPINS ARE SWITCHED OFF
		--
		-- The products exist in the dashboard and are on sale there, so a
		-- receipt can name one before this build sells them: bought outside
		-- the game, or prompted by a tampered client. NOT granted and NOT
		-- acknowledged, like any product this build cannot honour: nothing is
		-- given that the rules for a paid random item have not been met for,
		-- and Roblox returns the Robux when it stops retrying.
		--======================================================================
		warn(string.format(
			"[Seed/StoreService] receipt for the wheel's %q (product %s) from %s while paid spins are "
			.. "switched off. Not granted, not acknowledged.",
			wheelOff[info.ProductId], tostring(info.ProductId), player.Name))
		return RETRY
	end
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

local function processReceipt(info: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		-- Gone. Roblox re-delivers when they come back, and the ledger check
		-- will still be the thing that stops a double grant.
		return RETRY
	end

	local profile = PlayerDataService.Get(player)
	if not profile then
		-- Their save has not arrived. Granting into a profile that is about to
		-- be replaced by the loaded one is how a purchase disappears.
		return RETRY
	end

	--==========================================================================
	-- ONE DELIVERY OF A RECEIPT AT A TIME
	--
	-- The ledger entry is written AFTER the grant, and a grant can yield: a
	-- spin asks PolicyService about a player it has no answer for yet. A
	-- second delivery of the same receipt arriving in that gap would find no
	-- entry and grant again. It is told "not yet" instead; the first delivery
	-- finishes, and Roblox delivers again if it still has to.
	--
	-- Released whatever happens, so a grant that throws leaves the receipt
	-- unacknowledged and retryable rather than shut out for the server's life.
	--==========================================================================
	local purchaseId = tostring(info.PurchaseId)
	if deciding[purchaseId] then
		return RETRY
	end
	deciding[purchaseId] = true
	decidingFor[player] = (decidingFor[player] or 0) + 1
	local ok, decision = pcall(decide, info, player, profile, purchaseId)
	deciding[purchaseId] = nil
	decidingFor[player] = if (decidingFor[player] or 1) > 1 then (decidingFor[player] :: number) - 1 else nil
	if not ok then
		warn(string.format("[Seed/StoreService] %s: receipt %s failed while it was being decided (%s); "
			.. "not acknowledging", player.Name, purchaseId, tostring(decision)))
		return RETRY
	end
	return decision :: Enum.ProductPurchaseDecision
end

function StoreService.Init()
	table.clear(deciding)
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
	local inWorld = {}
	for _, item in ipairs(STORE.InWorld or {}) do
		table.insert(inWorld, string.format("%s=%s", item.key,
			if (tonumber(item.product) or 0) > 0 then tostring(item.product) else "-"))
	end
	rows[#rows + 1] = string.format("  %-12s %s", "InWorld",
		if #inWorld == 0 then "(empty)" else table.concat(inWorld, " "))
	local wheel = {}
	for _, product in ipairs(WheelData.receiptProducts()) do
		table.insert(wheel, string.format("%s=%d x%d", product.key, product.productId, product.spins))
	end
	rows[#rows + 1] = string.format("  %-12s %s%s", "Wheel",
		if WheelData.paidLive() then "" else "OFF (WheelData.Paid.Enabled is false): ",
		if #wheel == 0 then "(no spin products)" else table.concat(wheel, " "))
	return table.concat(rows, "\n")
end

return StoreService
