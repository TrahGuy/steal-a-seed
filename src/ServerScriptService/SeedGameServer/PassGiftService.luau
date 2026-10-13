--!strict
--==============================================================================
-- Steal a Seed :: PassGiftService (2026-10-13, the owner's backlog item 6:
-- "make the passes giftable")
--
-- A PASS AS A GIFT. Roblox cannot gift a Game Pass, so each pass has a GIFT
-- Developer Product at the pass's price (GameConfig.Store.PassGifts, `forPass`
-- naming the pass; the ids the owner's, 0 until created). Its receipt gives the
-- chosen player a GIFTED PASS: a row on THEIR profile (ProfileSchema
-- GiftedPasses) that PassService counts as the pass itself -- the multipliers,
-- the Bag's room, the hatch factor, VIP's gold name and chat tag, OWNED on the
-- Shop's card -- for good. The Mysterious Pod's gift flow (MysteryShopService),
-- for a pass:
--
--   ASKED FIRST  the client's Pass.Gift.Action { pass = key, recipient =
--                userId }, every argument a claim. Refused before any prompt:
--                no live gift product, nobody of that id here, the buyer
--                themselves, a profile not saving, or a recipient who ALREADY
--                HAS the pass, real or gifted (PassService.CheckOwns asks
--                Roblox again first): "Friend already has VIP." Otherwise the
--                recipient is noted for this buyer, then the prompt opens.
--   THE RECEIPT  (StoreService's decide, through SetPassGiftGrant): the noted
--                recipient's profile takes the row AND the receipt's id in one
--                step, then saves; acknowledged only once that save holds -- a
--                retry finds the id there, adds nothing, and only saves again.
--                Everybody here is told "Buyer gifted Friend VIP!", the
--                recipient "Buyer gifted you VIP!".
--   GONE         a recipient who left before the receipt, one whose profile is
--                not saving by then, or no note at all (a restart, or older
--                than Gift.NoteSeconds): the pass is the BUYER's own, the row on
--                their profile beside their own ledger entry (StoreService's),
--                and they are told why.
--   THE RACE     whoever gets the row already had the pass by then (bought it,
--                or was gifted it, between the prompt and the receipt): the
--                row is STILL written, so no purchase goes unrecorded, and the
--                log says RACE for the owner to make good (backlog item 6's
--                default; the owner's call).
--
-- The buyer's ledger and the buyer's save are StoreService's, as for every
-- product.
--==============================================================================
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Notice = require(Shared:WaitForChild("Notice"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local PassService = require(script.Parent:WaitForChild("PassService"))
local StoreService = require(script.Parent:WaitForChild("StoreService"))

local PassGiftService = {}
-- After StoreService (66), whose receipts this grants.
PassGiftService.Priority = 80

local GIFT = GameConfig.Pass.Gift
local WORDS = GIFT.Words
local SAVE = GameConfig.Save

local function log(message: string)
	print("[Seed/PassGiftService] " .. message)
end

-- The gift products by key, and by the pass each gives.
local byKey: { [string]: any } = {}
local byPass: { [string]: any } = {}
for _, item in ipairs((GameConfig.Store :: any).PassGifts or {}) do
	byKey[tostring(item.key)] = item
	byPass[tostring(item.forPass)] = item
end
PassGiftService.Gifts = byKey
PassGiftService.ByPass = byPass

--==============================================================================
-- THE SEAMS (a spec stands these in)
--==============================================================================
PassGiftService.Hooks = {
	byUserId = function(userId: number): Player?
		return Players:GetPlayerByUserId(userId)
	end,
	players = function(): { Player }
		return Players:GetPlayers()
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
	-- When a row was written (os.time, as ProfileSchema keeps it).
	now = function(): number
		return os.time()
	end,
}
local Hooks = PassGiftService.Hooks

local function nameOf(player: Player): string
	local name = (player :: any).DisplayName
	return if type(name) == "string" and name ~= "" then name else player.Name
end

-- A pass's own words, as its card prints them: "VIP", "+12 BAG SLOTS".
local function passWord(key: string): string
	local row = PassService.Row(key)
	return if row and type(row.label) == "string" then row.label else key
end
PassGiftService.passWord = passWord

local noticeCount = 0
local function tell(player: Player, title: string)
	noticeCount += 1
	Hooks.send(player, Notice.ServerNotice, { title = title, key = "passgift:" .. noticeCount })
end

-- One line for everybody here but `skip` (who is told in their own words).
local function announce(title: string, skip: Player)
	noticeCount += 1
	local key = "passgifted:" .. noticeCount
	for _, other in ipairs(Hooks.players()) do
		if other ~= skip then
			Hooks.send(other, Notice.ServerNotice, { title = title, key = key })
		end
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
-- THE ROW: one gifted pass on `target`'s profile, in one step -- and, for a
-- gift to ANOTHER player (`ledger`), the receipt's id into their Receipts in
-- that same step, so their save holds both or neither. The buyer's own ledger
-- is StoreService's. False when the profile is not here or is full
-- (Save.MaxGiftedPasses). Never yields.
--==============================================================================
local function record(target: Player, passKey: string, from: number, purchaseId: string, ledger: boolean): boolean
	local done = false
	PlayerDataService.UpdateGiftedPasses(target, function(p: any): boolean
		local rows = p.GiftedPasses
		if type(rows) ~= "table" then
			rows = {}
			p.GiftedPasses = rows
		end
		if #rows >= SAVE.MaxGiftedPasses then
			return false
		end
		table.insert(rows, { Pass = passKey, From = from, Receipt = purchaseId, At = Hooks.now() })
		if ledger then
			local list = p.Receipts
			table.insert(list, purchaseId)
			while #list > SAVE.MaxReceipts do
				table.remove(list, 1)
			end
		end
		done = true
		return true
	end)
	return done
end

--==============================================================================
-- A GIFT, ASKED FOR (the client's Pass.Gift.Action). The answer goes back on
-- Pass.Gift.Reply: { ok, code, words? } -- `words` the refusal said whole, where
-- it names somebody.
--==============================================================================
type Note = { product: number, pass: string, recipient: number, name: string, at: number }
local notes: { [Player]: Note } = setmetatable({} :: any, { __mode = "k" })
local lastAsk: { [Player]: number } = setmetatable({} :: any, { __mode = "k" })

function PassGiftService.AskGift(buyer: Player, payload: any)
	local now = Hooks.clock()
	if now - (lastAsk[buyer] or -math.huge) < GIFT.Cooldown then
		return
	end
	lastAsk[buyer] = now
	local function reply(ok: boolean, code: string, words: string?)
		Hooks.send(buyer, GIFT.Reply, { ok = ok, code = code, words = words })
	end
	if type(payload) ~= "table" then
		return
	end
	local passKey = tostring(payload.pass)
	local item = byPass[passKey]
	if not (item and PassService.Row(passKey) and (tonumber(item.product) or 0) > 0) then
		return reply(false, "NO_GIFT")
	end
	local recipientId = tonumber(payload.recipient)
	if not recipientId or recipientId ~= recipientId or recipientId ~= math.floor(recipientId) then
		return reply(false, "NO_PLAYER")
	end
	local recipient = Hooks.byUserId(recipientId)
	if not recipient or recipient == buyer or recipient.Parent ~= Players then
		return reply(false, "NO_PLAYER")
	end
	if not (PlayerDataService.Get(recipient) and PlayerDataService.IsPersistent(recipient)) then
		return reply(false, "NOT_SAVING")
	end
	-- Asks Roblox again when the cache says no, so this yields.
	if PassService.CheckOwns(recipient, passKey) then
		return reply(false, "ALREADY", string.format(WORDS.Refused.ALREADY, nameOf(recipient), passWord(passKey)))
	end
	-- Either may have left while Roblox was asked.
	if buyer.Parent ~= Players or recipient.Parent ~= Players then
		return
	end
	notes[buyer] = { product = item.product, pass = passKey, recipient = recipientId, name = nameOf(recipient),
		at = Hooks.clock() }
	Hooks.prompt(buyer, item.product)
	reply(true, "PROMPTED")
end

--==============================================================================
-- A GIFT'S RECEIPT (StoreService, inside its decide): true once the row is
-- written -- a gift to another player's in their SAVED profile -- false to
-- leave the receipt open.
--==============================================================================
function PassGiftService.Grant(buyer: Player, item: any, purchaseId: string): boolean
	local passKey = tostring(item.forPass)
	if not PassService.Row(passKey) then
		warn(string.format("[Seed/PassGiftService] %s: %q names no pass this build sells (%q); the receipt stays "
			.. "open.", buyer.Name, tostring(item.key), passKey))
		return false
	end
	local word = passWord(passKey)
	local note = notes[buyer]
	local fresh = note ~= nil and note.product == item.product and Hooks.clock() - note.at <= GIFT.NoteSeconds
	local recipient: Player? = nil
	-- The noted recipient is no longer in this server (said by name, below).
	local gone = false
	if fresh then
		local other = Hooks.byUserId((note :: Note).recipient)
		if other and other ~= buyer and other.Parent == Players then
			if PlayerDataService.Get(other) and PlayerDataService.IsPersistent(other) then
				recipient = other
			end
		else
			gone = true
		end
	end
	if recipient then
		-- THE GIFT: the row and this receipt's id into their profile, then their
		-- save. A retry -- their save failed last time -- finds the id there,
		-- writes nothing more, and only saves again.
		local theirs = PlayerDataService.Get(recipient)
		local had = false
		if not (theirs and inLedger(theirs, purchaseId)) then
			had = PassService.Owns(recipient, passKey)
			if not record(recipient, passKey, buyer.UserId, purchaseId, true) then
				warn(string.format("[Seed/PassGiftService] %s: %q could not be written for %s now (no profile, or "
					.. "%d gifted passes already); the receipt stays open.", buyer.Name, tostring(item.key),
					recipient.Name, SAVE.MaxGiftedPasses))
				return false
			end
		end
		if not PlayerDataService.Save(recipient) then
			warn(string.format("[Seed/PassGiftService] %s's gift to %s not saved yet; the receipt stays open.",
				buyer.Name, recipient.Name))
			return false
		end
		notes[buyer] = nil
		PassService.Refresh(recipient)
		tell(recipient, string.format(WORDS.GiftedYou, nameOf(buyer), word))
		announce(string.format(WORDS.Gifted, nameOf(buyer), nameOf(recipient), word), recipient)
		if had then
			warn(string.format("[Seed/PassGiftService] RACE: %s gifted %s %q, which %s already had by the receipt "
				.. "(%s). Recorded anyway; the owner decides any make-good.", buyer.Name, recipient.Name, passKey,
				recipient.Name, purchaseId))
			tell(buyer, string.format(WORDS.AlreadyHad, nameOf(recipient), word))
		end
		log(string.format("%s gifted %s %q (%s).", buyer.Name, recipient.Name, passKey, purchaseId))
		return true
	end
	-- THE BUYER'S OWN: the recipient has gone, cannot keep it now (no saving
	-- profile), or nobody was noted.
	local had = PassService.Owns(buyer, passKey)
	if not record(buyer, passKey, buyer.UserId, purchaseId, false) then
		warn(string.format("[Seed/PassGiftService] %s: %q could not be written now (no profile, or %d gifted passes "
			.. "already); the receipt stays open.", buyer.Name, tostring(item.key), SAVE.MaxGiftedPasses))
		return false
	end
	notes[buyer] = nil
	PassService.Refresh(buyer)
	local name = if gone then (note :: Note).name else nil
	if had then
		warn(string.format("[Seed/PassGiftService] RACE: %s's gift of %q fell back to them, and they already had it "
			.. "(%s). Recorded anyway; the owner decides any make-good.", buyer.Name, passKey, purchaseId))
		tell(buyer, if name then string.format(WORDS.GiftLeftHad, name, word)
			else string.format(WORDS.GiftUnsentHad, word))
	else
		tell(buyer, if name then string.format(WORDS.GiftLeft, name, word) else string.format(WORDS.GiftUnsent, word))
	end
	log(string.format("%s: the gift of %q is their own (%s).", buyer.Name, passKey,
		if name then name .. " left" else "no recipient to give it to"))
	return true
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function PassGiftService.Init() end

function PassGiftService.Start()
	StoreService.SetPassGiftGrant(PassGiftService.Grant)
	local remotes = SeedGame:FindFirstChild("Remotes")
	local channel = remotes and remotes:FindFirstChild(GameConfig.Remotes.GameEvent)
	if channel and channel:IsA("RemoteEvent") then
		(channel :: RemoteEvent).OnServerEvent:Connect(function(player: Player, action: any, payload: any)
			if action == GIFT.Action then
				PassGiftService.AskGift(player, payload)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		notes[player] = nil
		lastAsk[player] = nil
	end)
	local live, pending = 0, 0
	for _, item in pairs(byKey) do
		if (tonumber(item.product) or 0) > 0 then
			live += 1
		else
			pending += 1
		end
	end
	log(string.format("Ready. %d pass gift product(s) live, %d waiting for an id; recipients noted before "
		.. "their prompt.", live, pending))
end

return PassGiftService
