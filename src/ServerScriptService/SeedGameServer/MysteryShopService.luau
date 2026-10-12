--!strict
--==============================================================================
-- Steal a Seed :: MysteryShopService (2026-10-12, the owner's item 17)
--
-- THE MYSTERIOUS POD, SOLD (GameConfig.Store.MysteryPods): bundles of 1, 3, 10
-- and 50 of the Enchanted Mist's Mysterious Pod -- each the very pod a delivery
-- earns, its creature and size rolled at the grant (MysteryPodService.Grant) --
-- for the buyer, or as a GIFT to another player in this server.
--
--   THE GATE     a paid random item: offered, prompted and granted only to a
--                player PolicyService allows (WheelService.PolicyAllows,
--                fail-closed; the client's flag is Mystery.Shop's
--                PolicyAttribute). A receipt for anybody else is not
--                acknowledged, and Roblox returns the Robux.
--   A GIFT       asked for here first (Shop.GiftAction): the recipient is
--                noted, then this server opens the gift's prompt. Its receipt
--                hands the pods to the noted recipient -- their save holding the
--                pods AND the receipt's id together, so a retried receipt finds
--                the id and grants nothing twice -- or, if they have gone, to
--                the buyer with a notice. Everybody here is told "X gifted Y N
--                Mysterious Pods!".
--   NEVER LOST   pods with no Bag room are OWED (the profile's MysteryPodsOwed,
--                in the receipt's own step) and handed over here as room comes;
--                a progress reset keeps them (PlayerDataService.ResetProgress).
--
-- StoreService decides the receipt (its ledger, its save of the buyer) and
-- calls Grant through the hook this hands it at Start.
--==============================================================================
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Notice = require(Shared:WaitForChild("Notice"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local MysteryPodService = require(script.Parent:WaitForChild("MysteryPodService"))
local WheelService = require(script.Parent:WaitForChild("WheelService"))
local StoreService = require(script.Parent:WaitForChild("StoreService"))

local MysteryShopService = {}
-- After MysteryPodService (78), whose grant this sells.
MysteryShopService.Priority = 79

local SHOP = EnchantedMistConfig.Mystery.Shop
local WORDS = SHOP.Words
local SAVE = GameConfig.Save
-- One gift request per player this often.
local GIFT_COOLDOWN = 1
-- A gift's note stands this long: a prompt answered later is the buyer's own.
local NOTE_SECONDS = 600
-- Owed pods are offered to the Bag this often.
local OWED_EVERY = 1

local function log(message: string)
	print("[Seed/MysteryShopService] " .. message)
end

-- The bundles by product id and by key.
local byProduct: { [number]: any } = {}
local byKey: { [string]: any } = {}
for _, item in ipairs((GameConfig.Store :: any).MysteryPods or {}) do
	byProduct[item.product] = item
	byKey[item.key] = item
end
MysteryShopService.Bundles = byKey

--==============================================================================
-- THE SEAMS (a spec stands these in)
--==============================================================================
MysteryShopService.Hooks = {
	players = function(): { Player }
		return Players:GetPlayers()
	end,
	byUserId = function(userId: number): Player?
		return Players:GetPlayerByUserId(userId)
	end,
	-- One GameEvent message to one player.
	send = function(player: Player, action: string, payload: { [string]: any })
		local remotes = SeedGame:FindFirstChild("Remotes")
		local remote = remotes and remotes:FindFirstChild(GameConfig.Remotes.GameEvent)
		if remote and remote:IsA("RemoteEvent") and player.Parent == Players then
			(remote :: RemoteEvent):FireClient(player, action, payload)
		end
	end,
	prompt = function(player: Player, productId: number)
		MarketplaceService:PromptProductPurchase(player, productId)
	end,
	clock = function(): number
		return os.clock()
	end,
	-- PolicyService's answer for this player, asked again only when it says no
	-- (nothing yet, or a failed call): WheelService's fail-closed one.
	allowed = function(player: Player): boolean
		if not WheelService.PolicyAllows(player) then
			WheelService.CheckPolicy(player)
		end
		return WheelService.PolicyAllows(player)
	end,
	-- The answer already had, never asking (a recipient's, at the receipt).
	known = function(player: Player): boolean
		return WheelService.PolicyAllows(player)
	end,
}
local Hooks = MysteryShopService.Hooks

local function nameOf(player: Player): string
	local name = (player :: any).DisplayName
	return if type(name) == "string" and name ~= "" then name else player.Name
end

-- "a Mysterious Pod" / "3 Mysterious Pods".
local function podsWord(count: number): string
	return if count == 1 then "a Mysterious Pod" else string.format("%d Mysterious Pods", count)
end
MysteryShopService.podsWord = podsWord

local noticeCount = 0
local function tell(player: Player, title: string)
	noticeCount += 1
	Hooks.send(player, Notice.ServerNotice, { title = title, key = "mysteryshop:" .. noticeCount, icon = "mist" })
end

-- One line for everybody here, the buyer and the recipient included.
local function announce(title: string)
	noticeCount += 1
	local key = "mysterygift:" .. noticeCount
	for _, other in ipairs(Hooks.players()) do
		Hooks.send(other, Notice.ServerNotice, { title = title, key = key, icon = "mist" })
	end
end

local function inLedger(profile: any, purchaseId: string): boolean
	for _, id in ipairs(profile.Receipts or {}) do
		if id == purchaseId then
			return true
		end
	end
	return false
end

--==============================================================================
-- INTO A BAG, THE REST OWED
--
-- `count` pods for `target`: into the Bag as far as it has room, the rest owed
-- -- refused whole (false) if the owed would pass Save.MaxMysteryPodsOwed, so
-- a retry never finds half a grant. `receipt`: a gift's purchase id, written
-- into the recipient's own ledger in the same step. Never yields. Answers ok,
-- how many went in and how many are owed.
--==============================================================================
local function deliver(target: Player, count: number, receipt: string?): (boolean, number, number)
	local profile = PlayerDataService.Get(target)
	if not profile or not PlayerDataService.IsPersistent(target) then
		return false, 0, 0
	end
	local room, _, known = CarryService.PodRoom(target)
	local fit = if known and CarryService.IsHeldRestored(target) then math.clamp(room, 0, count) else 0
	if (tonumber((profile :: any).MysteryPodsOwed) or 0) + (count - fit) > SAVE.MaxMysteryPodsOwed then
		return false, 0, 0
	end
	local given = 0
	PlayerDataService.UpdateDewberries(target, function(p: any): boolean
		for _ = 1, fit do
			if not (MysteryPodService.Grant(target, p, nil)) then
				break
			end
			given += 1
		end
		if receipt then
			local list = p.Receipts
			table.insert(list, receipt)
			while #list > SAVE.MaxReceipts do
				table.remove(list, 1)
			end
		end
		return given > 0 or receipt ~= nil
	end)
	local owed = count - given
	if owed > 0 then
		PlayerDataService.AddMysteryPodsOwed(target, owed)
	end
	if given > 0 then
		MysteryPodService.Hooks.saveSoon(target)
	end
	return true, given, owed
end

--==============================================================================
-- A GIFT, ASKED FOR (the client's Shop.GiftAction: { bundle = key, recipient =
-- userId }). Every argument a claim. The recipient is noted for this buyer,
-- then the gift's prompt opens; the answer goes back on Shop.GiftReply.
--==============================================================================
type Note = { product: number, recipient: number, name: string, at: number }
local notes: { [Player]: Note } = setmetatable({} :: any, { __mode = "k" })
local lastAsk: { [Player]: number } = setmetatable({} :: any, { __mode = "k" })

function MysteryShopService.AskGift(buyer: Player, payload: any)
	local now = Hooks.clock()
	if now - (lastAsk[buyer] or -math.huge) < GIFT_COOLDOWN then
		return
	end
	lastAsk[buyer] = now
	local function reply(ok: boolean, code: string)
		Hooks.send(buyer, SHOP.GiftReply, { ok = ok, code = code })
	end
	if type(payload) ~= "table" then
		return
	end
	local item = byKey[tostring(payload.bundle)]
	local recipientId = tonumber(payload.recipient)
	if not (item and item.gift == true and (tonumber(item.product) or 0) > 0) then
		return reply(false, "NO_BUNDLE")
	end
	if not recipientId or recipientId ~= recipientId or recipientId ~= math.floor(recipientId) then
		return reply(false, "NO_PLAYER")
	end
	local recipient = Hooks.byUserId(recipientId)
	if not recipient or recipient == buyer or recipient.Parent ~= Players then
		return reply(false, "NO_PLAYER")
	end
	if not MysteryPodService.CanGrant() then
		return reply(false, "OFF")
	end
	if not PlayerDataService.IsPersistent(recipient) then
		return reply(false, "NOT_SAVING")
	end
	if not (Hooks.allowed(buyer) and Hooks.allowed(recipient)) then
		return reply(false, "RESTRICTED")
	end
	notes[buyer] = { product = item.product, recipient = recipientId, name = nameOf(recipient), at = now }
	Hooks.prompt(buyer, item.product)
	reply(true, "PROMPTED")
end

--==============================================================================
-- A BUNDLE'S RECEIPT (StoreService, inside its decide): true once the pods are
-- given or owed -- a gift's in the recipient's SAVED profile -- false to leave
-- the receipt open. The buyer's ledger and save are StoreService's.
--==============================================================================
function MysteryShopService.Grant(buyer: Player, item: any, purchaseId: string): boolean
	local count = math.floor(tonumber(item.count) or 0)
	if count < 1 or not MysteryPodService.CanGrant() then
		warn(string.format("[Seed/MysteryShopService] %s: %q cannot be granted now (no shell bound, or no count); "
			.. "the receipt stays open.", buyer.Name, tostring(item.key)))
		return false
	end
	if not Hooks.allowed(buyer) then
		warn(string.format("[Seed/MysteryShopService] %s: a %q receipt, and PolicyService does not allow paid "
			.. "random items for them (or has not answered). Not granted; the receipt stays open.", buyer.Name,
			tostring(item.key)))
		return false
	end
	local note = notes[buyer]
	local recipient: Player? = nil
	if item.gift == true and note and note.product == item.product and Hooks.clock() - note.at <= NOTE_SECONDS then
		local other = Hooks.byUserId(note.recipient)
		if other and other ~= buyer and other.Parent == Players and PlayerDataService.Get(other)
			and PlayerDataService.IsPersistent(other) and Hooks.known(other) then
			recipient = other
		end
	end
	if recipient then
		-- THE GIFT: into their profile with this receipt's id, then their save.
		-- A retry -- their save failed last time -- finds the id there, gives
		-- nothing more, and only saves again.
		local theirs = PlayerDataService.Get(recipient)
		local given, owed = 0, 0
		if not (theirs and inLedger(theirs, purchaseId)) then
			local ok
			ok, given, owed = deliver(recipient, count, purchaseId)
			if not ok then
				warn(string.format("[Seed/MysteryShopService] %s: %q could not be given to %s now (no profile "
					.. "saving, or too many owed); the receipt stays open.", buyer.Name, tostring(item.key),
					recipient.Name))
				return false
			end
		end
		if not PlayerDataService.Save(recipient) then
			warn(string.format("[Seed/MysteryShopService] %s's gift to %s not saved yet; the receipt stays open.",
				buyer.Name, recipient.Name))
			return false
		end
		notes[buyer] = nil
		announce(string.format(WORDS.Gifted, nameOf(buyer), nameOf(recipient), podsWord(count)))
		if owed > 0 then
			tell(recipient, string.format(WORDS.Owed, podsWord(owed)))
		end
		log(string.format("%s: %q -> %s: %d into the Bag, %d owed.", buyer.Name, tostring(item.key), recipient.Name,
			given, owed))
		return true
	end
	-- THE BUYER'S OWN -- or a gift whose recipient has gone.
	local ok, given, owed = deliver(buyer, count, nil)
	if not ok then
		warn(string.format("[Seed/MysteryShopService] %s: %q could not be given now (no profile saving, or too "
			.. "many owed); the receipt stays open.", buyer.Name, tostring(item.key)))
		return false
	end
	if item.gift == true then
		local left = note and note.product == item.product
		notes[buyer] = nil
		tell(buyer, if left
			then string.format(WORDS.GiftLeft, (note :: Note).name, podsWord(count))
			else string.format(WORDS.GiftUnsent, podsWord(count)))
	end
	if owed > 0 then
		tell(buyer, string.format(WORDS.Owed, podsWord(owed)))
	end
	log(string.format("%s: %q: %d into the Bag, %d owed.", buyer.Name, tostring(item.key), given, owed))
	return true
end

--==============================================================================
-- OWED PODS, HANDED OVER AS ROOM COMES
--==============================================================================
function MysteryShopService.DeliverOwed(player: Player): number
	local profile = PlayerDataService.Get(player)
	local owed = if profile then math.floor(tonumber((profile :: any).MysteryPodsOwed) or 0) else 0
	if owed <= 0 or not MysteryPodService.CanGrant() or not CarryService.IsHeldRestored(player) then
		return 0
	end
	local room, _, known = CarryService.PodRoom(player)
	if not known or room <= 0 then
		return 0
	end
	local fit = math.min(owed, room)
	local given = 0
	PlayerDataService.UpdateDewberries(player, function(p: any): boolean
		for _ = 1, fit do
			if not (MysteryPodService.Grant(player, p, nil)) then
				break
			end
			given += 1
		end
		return given > 0
	end)
	if given > 0 then
		PlayerDataService.AddMysteryPodsOwed(player, -given)
		MysteryPodService.Hooks.saveSoon(player)
		tell(player, string.format(WORDS.Delivered, podsWord(given)))
		log(string.format("%s: %d owed Mysterious Pod(s) handed over, %d still owed.", player.Name, given,
			owed - given))
	end
	return given
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function MysteryShopService.Init() end

function MysteryShopService.Start()
	StoreService.SetMysteryGrant(MysteryShopService.Grant)
	local remotes = SeedGame:FindFirstChild("Remotes")
	local channel = remotes and remotes:FindFirstChild(GameConfig.Remotes.GameEvent)
	if channel and channel:IsA("RemoteEvent") then
		(channel :: RemoteEvent).OnServerEvent:Connect(function(player: Player, action: any, payload: any)
			if action == SHOP.GiftAction then
				MysteryShopService.AskGift(player, payload)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		notes[player] = nil
		lastAsk[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(OWED_EVERY)
			for _, player in ipairs(Hooks.players()) do
				local ok, err = pcall(MysteryShopService.DeliverOwed, player)
				if not ok then
					warn("[Seed/MysteryShopService] owed delivery failed: " .. tostring(err))
				end
			end
		end
	end)
	local live = 0
	for _ in pairs(byProduct) do
		live += 1
	end
	log(string.format("Ready. %d Mysterious Pod product(s), gifts noted before their prompt.", live))
end

return MysteryShopService
