--!nocheck
--==============================================================================
-- Steal a Seed :: PassGiftSpec (2026-10-13, the owner's backlog item 6: "make
-- the passes giftable")
--
--   1. the products: one GIFT Developer Product per pass, at the pass's own
--      price, naming it by `forPass` (never `pass`, which StoreService skips as
--      a Game Pass), 0 until the owner creates it, no id twice
--   2. what a gift is worth: the REAL PassService over stand-in profiles -- a
--      gifted row counts as the pass (x2 and VIP stack, the Bag's room, the
--      hatch factor, VIP, Owns), a key this build does not sell counts for
--      nothing, and the published PassesOwned list
--   3. the save: ProfileSchema keeps whole rows, in order, capped, a renamed
--      pass's row too; a progress reset keeps them
--   4. the gift: the REAL PassGiftService against stand-ins -- refused before
--      any prompt (no product, nobody, yourself, not saving, already has it,
--      real or gifted); noted, then prompted; the receipt writes the row and
--      the receipt's id on the recipient, acknowledged only once they save (a
--      retry writes nothing more); everybody told, the recipient in their own
--      words; the recipient gone, or no note: the buyer's own; the race:
--      recorded and said; the cap: refused whole
--   5. the wiring: StoreService indexes and routes them; nothing but
--      PassService asks Roblox who owns a pass on the server; the Shop's GIFT,
--      OWNED from the attribute, the sheet, the controller's stops; GIFT's
--      room on a tile and on a phone's row
--
-- Not here, seen in Play instead: a real purchase prompt and receipt (Studio
-- cannot buy), two players in one server.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local ShopCatalog = require(Shared:WaitForChild("ShopCatalog"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local GIFT = GameConfig.Pass.Gift
local WORDS = GIFT.Words

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function strip(src)
	return (string.gsub(src, "%-%-[^\n]*", ""))
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
local function near(a, b)
	return math.abs(a - b) < 1e-9
end
local function sourceOf(parent, name)
	local found = parent:FindFirstChild(name, true)
	return if found then strip(found.Source) else ""
end

-- A server module, its siblings stood in.
local function load(name, siblings)
	local chunk = assert(loadstring(Server:WaitForChild(name).Source, "=" .. name))
	local parent = {}
	function parent:WaitForChild(child)
		assert(siblings[child] ~= nil, name .. " asked for an unexpected sibling " .. child)
		return { __standIn = siblings[child] }
	end
	setfenv(chunk, setmetatable({
		script = { Name = name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return require(target)
		end,
	}, { __index = getfenv(1) }))
	return chunk()
end

local ok, err = pcall(function()
	local PASSES = GameConfig.Store.Items.Passes
	local passBy = {}
	for _, row in ipairs(PASSES) do
		passBy[row.key] = row
	end

	--==========================================================================
	say("1. The products")
	--==========================================================================
	local gifts = GameConfig.Store.PassGifts or {}
	-- The owner's ids (created 2026-10-13; each name checked against economy
	-- details -- "Gift: x2 Money", "Gift: +12 Bag Slots", "Gift: Faster Hatch",
	-- "Gift: VIP" -- the prices the owner's list).
	local OWNER = { giftx2money = 3718302369, giftbagslots = 3718302049, giftfasterhatch = 3718302137,
		giftvip = 3718302234 }
	local wrong, seenFor = {}, {}
	for _, item in ipairs(gifts) do
		local target = passBy[tostring(item.forPass)]
		if not (target and item.robux == target.robux and item.kind == "passgift" and item.pass == nil
			and type(item.key) == "string" and item.product == OWNER[item.key] and not seenFor[item.forPass]) then
			table.insert(wrong, tostring(item.key))
		end
		seenFor[tostring(item.forPass)] = true
	end
	local everyPass = true
	for key in pairs(passBy) do
		everyPass = everyPass and seenFor[key] == true
	end
	-- No id twice anywhere the store sells from.
	local seen, twice = {}, {}
	local function scan(list)
		for _, item in ipairs(list or {}) do
			local id = tonumber(item.product) or 0
			if id > 0 then
				if seen[id] then
					table.insert(twice, tostring(id))
				end
				seen[id] = true
			end
		end
	end
	for _, section in ipairs(GameConfig.Store.Sections) do
		scan(GameConfig.Store.Items[section.id])
	end
	scan(GameConfig.Store.InWorld)
	scan(GameConfig.Store.MysteryPods)
	scan(gifts)
	check(#gifts == #PASSES and #wrong == 0 and everyPass and #twice == 0,
		"one GIFT product per pass, the owner's id, at the pass's own price, named by forPass (no `pass` field), "
			.. "no id twice", table.concat(wrong, ",") .. " | " .. table.concat(twice, ","))
	check(ShopCatalog.giftFor("vip") == OWNER.giftvip and ShopCatalog.giftFor("x2money") == OWNER.giftx2money
			and ShopCatalog.giftFor("bagslots") == OWNER.giftbagslots
			and ShopCatalog.giftFor("fasterhatch") == OWNER.giftfasterhatch and ShopCatalog.giftFor("nosuchpass") == nil,
		"each pass's card carries its gift product (ShopCatalog.giftFor); a pass with none -- or an id of 0 -- has no GIFT")

	--==========================================================================
	say("2. What a gift is worth (the real PassService, stand-in profiles)")
	--==========================================================================
	local attrs = {}
	local function standIn(name, userId)
		local p = { Name = name, DisplayName = name, UserId = userId, Parent = Players }
		attrs[p] = {}
		function p:SetAttribute(key, value)
			attrs[self][key] = value
		end
		function p:GetAttribute(key)
			return attrs[self][key]
		end
		return p
	end
	local buyer = standIn("Buyer", 90000000201)
	local friend = standIn("Friend", 90000000202)
	local profiles, persistent, saves, saveFails = {}, {}, {}, {}
	local PDS = {
		Get = function(p)
			return profiles[p]
		end,
		IsPersistent = function(p)
			return persistent[p] ~= false
		end,
		UpdateGiftedPasses = function(p, change)
			local prof = profiles[p]
			if not prof then
				return false
			end
			return change(prof)
		end,
		Save = function(p)
			saves[p] = (saves[p] or 0) + 1
			return not saveFails[p]
		end,
	}
	local PS = load("PassService", { PlayerDataService = PDS })
	PS.Init()
	PS.Changed = { Fire = function() end }
	local function row(key, receipt)
		return { Pass = key, From = buyer.UserId, Receipt = receipt or ("R-" .. key), At = 1 }
	end
	profiles[friend] = { Receipts = {}, GiftedPasses = { row("vip") } }
	local vipOnly = PS.Owns(friend, "vip") and PS.IsVip(friend) and near(PS.CashMultiplier(friend), 1.1)
		and PS.BagBonus(friend) == 0 and PS.HatchFactor(friend) == 1 and not PS.Owns(friend, "x2money")
	profiles[friend].GiftedPasses = { row("x2money"), row("bagslots"), row("fasterhatch"), row("vip") }
	local all = near(PS.CashMultiplier(friend), 2.2) and PS.BagBonus(friend) == 12
		and near(PS.HatchFactor(friend), 0.75) and PS.IsVip(friend)
	profiles[friend].GiftedPasses = { row("rocketboots") }
	local unknown = not PS.Owns(friend, "rocketboots") and PS.CashMultiplier(friend) == 1 and not PS.IsVip(friend)
	profiles[friend] = nil
	local unloaded = PS.CashMultiplier(friend) == 1 and not PS.Owns(friend, "vip")
	check(vipOnly and all and unknown and unloaded,
		"a gifted row IS the pass: VIP alone (gold, x1.1), all four (x2.2, +12 room, 0.75 of a wait, VIP); a key "
			.. "this build does not sell, or a profile not loaded yet, is worth nothing")
	profiles[friend] = { Receipts = {}, GiftedPasses = { row("vip"), row("x2money") } }
	PS.Refresh(friend)
	local a = attrs[friend]
	check(a[GameConfig.Pass.OwnedAttribute] == "vip,x2money" and near(a[GameConfig.Pass.MultiplierAttribute], 2.2)
			and a[GameConfig.Pass.VipAttribute] == true
			and a[GameConfig.Pass.BagSlotsAttribute] == GameConfig.Save.MaxHeld,
		"published: PassesOwned \"vip,x2money\" (sorted), the multiplier, VIP and the Bag's room",
		tostring(a[GameConfig.Pass.OwnedAttribute]))

	--==========================================================================
	say("3. The save")
	--==========================================================================
	local Schema = require(Server:WaitForChild("ProfileSchema"))
	local d = Schema.Default()
	local s = Schema.Sanitise({ GiftedPasses = {
		{ Pass = "vip", From = 90000000201, Receipt = "A1", At = 1760000000 },
		{ Pass = "renamedpass", From = 5, Receipt = "A2", At = 1 },
		{ Pass = "bad key!", From = 5, Receipt = "A3", At = 1 },
		{ Pass = "vip", From = 5 },
		"junk",
		{ Pass = "vip", From = -7, Receipt = "A4", At = -5 },
	} })
	local rows = s.GiftedPasses
	local many = {}
	for i = 1, GameConfig.Save.MaxGiftedPasses + 8 do
		many[i] = { Pass = "vip", From = 1, Receipt = "C" .. i, At = 1 }
	end
	local capped = Schema.Sanitise({ GiftedPasses = many }).GiftedPasses
	check(type(d.GiftedPasses) == "table" and #d.GiftedPasses == 0 and #rows == 3 and rows[1].Receipt == "A1"
			and rows[1].From == 90000000201 and rows[2].Pass == "renamedpass" and rows[3].From == 0 and rows[3].At == 0
			and #capped == GameConfig.Save.MaxGiftedPasses and capped[1].Receipt == "C1",
		"saved rows: whole ones only, in order, a renamed pass's kept, numbers clamped, at most Save.MaxGiftedPasses",
		string.format("%d rows, %d capped", #rows, #capped))
	local data = sourceOf(Server, "PlayerDataService")
	check(has(data, "GiftedPasses = table.clone(profile.GiftedPasses or {}),")
			and has(data, "function PlayerDataService.UpdateGiftedPasses(player: Player, change: (Profile) -> boolean): boolean"),
		"a progress reset keeps every gifted pass; rows are written through UpdateGiftedPasses")

	--==========================================================================
	say("4. The gift (the real PassGiftService, stand-ins round it)")
	--==========================================================================
	local Store = {
		SetPassGiftGrant = function() end,
	}
	local G = load("PassGiftService", { PlayerDataService = PDS, PassService = PS, StoreService = Store })
	-- A product id for the spec's own run (the owner's are 0 until created).
	local vipGift = table.clone(G.ByPass.vip)
	vipGift.product = 3899000001
	G.ByPass.vip = vipGift
	local sent, prompts = {}, {}
	local clock = 100
	local present = { [buyer.UserId] = buyer, [friend.UserId] = friend }
	G.Hooks.byUserId = function(id)
		return present[id]
	end
	G.Hooks.players = function()
		return { buyer, friend }
	end
	G.Hooks.send = function(p, action, payload)
		table.insert(sent, { p = p, action = action, payload = payload })
	end
	G.Hooks.prompt = function(p, id)
		table.insert(prompts, { p = p, id = id })
	end
	G.Hooks.clock = function()
		return clock
	end
	G.Hooks.now = function()
		return 1760400000
	end
	local function fresh()
		profiles[buyer] = { Receipts = {}, GiftedPasses = {} }
		profiles[friend] = { Receipts = {}, GiftedPasses = {} }
		persistent[buyer], persistent[friend] = true, true
		saves[buyer], saves[friend] = 0, 0
		table.clear(saveFails)
		table.clear(sent)
		table.clear(prompts)
		clock += 5
	end
	local function replies()
		local codes = {}
		for _, m in ipairs(sent) do
			if m.action == GIFT.Reply then
				table.insert(codes, tostring(m.payload.code) .. (if m.payload.words then "=" .. m.payload.words else ""))
			end
		end
		return table.concat(codes, ",")
	end
	local function told(p, title)
		for _, m in ipairs(sent) do
			if m.p == p and m.payload and m.payload.title == title then
				return true
			end
		end
		return false
	end

	-- Refused before any prompt (a pass with no gift product: NO_GIFT).
	fresh()
	G.AskGift(buyer, { pass = "nosuchpass", recipient = friend.UserId })
	clock += 2
	G.AskGift(buyer, { pass = "vip", recipient = 90000000999 })
	clock += 2
	G.AskGift(buyer, { pass = "vip", recipient = buyer.UserId })
	clock += 2
	persistent[friend] = false
	G.AskGift(buyer, { pass = "vip", recipient = friend.UserId })
	persistent[friend] = true
	clock += 2
	profiles[friend].GiftedPasses = { row("vip") }
	G.AskGift(buyer, { pass = "vip", recipient = friend.UserId })
	profiles[friend].GiftedPasses = {}
	clock += 0.2
	G.AskGift(buyer, { pass = "vip", recipient = friend.UserId })
	local refusals = replies()
	local wantRefusals = "NO_GIFT,NO_PLAYER,NO_PLAYER,NOT_SAVING,ALREADY="
		.. string.format(WORDS.Refused.ALREADY, "Friend", "VIP")
	check(#prompts == 0 and refusals == wantRefusals,
		"no prompt for a gift not on sale, nobody here, yourself, a profile not saving, or a player who has the "
			.. "pass (\"Friend already has VIP.\"); a second ask inside a second is ignored", refusals)

	-- Noted, prompted, then the receipt: their first save fails, so it stays open.
	fresh()
	G.AskGift(buyer, { pass = "vip", recipient = friend.UserId })
	local prompted = #prompts == 1 and prompts[1].p == buyer and prompts[1].id == vipGift.product
		and replies() == "PROMPTED"
	saveFails[friend] = true
	local first = G.Grant(buyer, vipGift, "G1")
	local inFirst = #profiles[friend].GiftedPasses == 1 and profiles[friend].Receipts[1] == "G1"
	saveFails[friend] = false
	local retry = G.Grant(buyer, vipGift, "G1")
	local theirs = profiles[friend].GiftedPasses
	check(prompted and first == false and inFirst and retry == true and #theirs == 1
			and theirs[1].Pass == "vip" and theirs[1].From == buyer.UserId and theirs[1].Receipt == "G1"
			and theirs[1].At == 1760400000 and #profiles[friend].Receipts == 1 and saves[friend] == 2
			and #profiles[buyer].GiftedPasses == 0 and #profiles[buyer].Receipts == 0 and PS.Owns(friend, "vip"),
		"a gift: noted, then prompted; its receipt writes the row AND the receipt's id on THEM in one step, is "
			.. "acknowledged only once they save -- the retry finds the id and writes nothing more -- and the buyer's "
			.. "ledger is left to StoreService")
	check(told(friend, string.format(WORDS.GiftedYou, "Buyer", "VIP"))
			and told(buyer, string.format(WORDS.Gifted, "Buyer", "Friend", "VIP"))
			and not told(friend, string.format(WORDS.Gifted, "Buyer", "Friend", "VIP"))
			and attrs[friend][GameConfig.Pass.OwnedAttribute] == "vip",
		"the recipient is told \"Buyer gifted you VIP!\", everybody else \"Buyer gifted Friend VIP!\", and their "
			.. "card's OWNED list has it")

	-- The recipient gone before the receipt: the buyer's own.
	fresh()
	G.AskGift(buyer, { pass = "vip", recipient = friend.UserId })
	present[friend.UserId] = nil
	local okGone = G.Grant(buyer, vipGift, "G2")
	present[friend.UserId] = friend
	local mine = profiles[buyer].GiftedPasses
	-- And no note at all (a restart): the buyer's own too.
	fresh()
	local okUnnoted = G.Grant(buyer, vipGift, "G3")
	local unnoted = profiles[buyer].GiftedPasses
	check(okGone and #mine == 1 and mine[1].From == buyer.UserId and #profiles[friend].GiftedPasses == 0
			and okUnnoted and #unnoted == 1 and told(buyer, string.format(WORDS.GiftUnsent, "VIP")),
		"the recipient gone before the receipt, or no note at all: the pass is the buyer's own, and they are told")
	fresh()
	G.AskGift(buyer, { pass = "vip", recipient = friend.UserId })
	present[friend.UserId] = nil
	G.Grant(buyer, vipGift, "G4")
	present[friend.UserId] = friend
	check(told(buyer, string.format(WORDS.GiftLeft, "Friend", "VIP")),
		"\"Friend left before the gift arrived, so VIP is yours.\"")

	-- The race: they came to have it between the prompt and the receipt.
	fresh()
	G.AskGift(buyer, { pass = "vip", recipient = friend.UserId })
	table.insert(profiles[friend].GiftedPasses, row("vip", "OTHER"))
	local okRace = G.Grant(buyer, vipGift, "G5")
	check(okRace and #profiles[friend].GiftedPasses == 2 and profiles[friend].GiftedPasses[2].Receipt == "G5"
			and told(buyer, string.format(WORDS.AlreadyHad, "Friend", "VIP")),
		"the race: a recipient who has the pass by the receipt still gets the row -- no purchase goes "
			.. "unrecorded -- and the buyer is told it is on record")

	-- The cap: refused whole.
	fresh()
	G.AskGift(buyer, { pass = "vip", recipient = friend.UserId })
	for i = 1, GameConfig.Save.MaxGiftedPasses do
		table.insert(profiles[friend].GiftedPasses, row("x2money", "F" .. i))
	end
	local okFull = G.Grant(buyer, vipGift, "G6")
	check(okFull == false and #profiles[friend].GiftedPasses == GameConfig.Save.MaxGiftedPasses
			and #profiles[friend].Receipts == 0,
		"a profile already holding Save.MaxGiftedPasses rows takes nothing, and the receipt stays open")

	-- A note older than NoteSeconds is the buyer's own (and never "left").
	fresh()
	G.AskGift(buyer, { pass = "vip", recipient = friend.UserId })
	clock += GIFT.NoteSeconds + 1
	local okOld = G.Grant(buyer, vipGift, "G7")
	check(okOld and #profiles[buyer].GiftedPasses == 1 and #profiles[friend].GiftedPasses == 0
			and told(buyer, string.format(WORDS.GiftUnsent, "VIP")),
		"a note older than Gift.NoteSeconds: the buyer's own, \"couldn't be delivered\"")

	--==========================================================================
	say("5. The wiring")
	--==========================================================================
	local store = sourceOf(Server, "StoreService")
	local giftSrc = sourceOf(Server, "PassGiftService")
	check(has(store, "for _, item in ipairs(STORE.PassGifts or {}) do")
			and has(store, "elseif item.kind == \"passgift\" then")
			and has(store, "function StoreService.SetPassGiftGrant(fn: (Player, any, string) -> boolean)")
			and has(giftSrc, "StoreService.SetPassGiftGrant(PassGiftService.Grant)")
			and has(giftSrc, "if action == GIFT.Action then\n\t\t\t\tPassGiftService.AskGift(player, payload)"),
		"StoreService indexes the gift products with every other id and hands their receipts to PassGiftService; "
			.. "the ask arrives on GameEvent")
	local askers = {}
	for _, d2 in ipairs(Server:GetDescendants()) do
		if d2:IsA("LuaSourceContainer") and d2.Name ~= "PassService" and has(strip(d2.Source), "UserOwnsGamePassAsync") then
			table.insert(askers, d2.Name)
		end
	end
	check(#askers == 0, "on the server only PassService asks Roblox who owns a pass: every benefit reads it",
		table.concat(askers, ","))
	local shop = sourceOf(Scripts, "ShopUI")
	check(has(shop, "local function ownsPass(entry: ShopCatalog.Entry): boolean")
			and has(shop, "elseif entry.kind == \"pass\" and ownsPass(entry) then")
			and has(shop, "\tif entry.kind == \"pass\" and ownsPass(entry) then\n\t\tSoundKit.play(\"Denied\")")
			and has(shop, "player:GetAttributeChangedSignal(GameConfig.Pass.OwnedAttribute):Connect(repaintPrices)"),
		"the Shop reads OWNED from the server's list too, so a gifted pass is never bought again")
	check(has(shop, "if entry.kind == \"pass\" and entry.gift then")
			and has(shop, "podBanner.giftTo({")
			and has(shop, "return { pass = entry.key, recipient = other.UserId }")
			and has(shop, "action = GIFT.Action,") and has(shop, "reply = GIFT.Reply,")
			and has(shop, "end, if gift then { p.hit, gift.hit } else p.hit)")
			and has(shop, "detailGift.hit.Visible = entry.kind == \"pass\" and entry.gift ~= nil")
			and has(shop, "add(page, gift.hit)") and has(shop, "add(page, detailGift.hit)"),
		"GIFT on a pass's card and in its details opens the Mysterious Pod's own sheet for everybody here; a press "
			.. "on it never opens the card; a controller reaches it after BUY")
	local S = MenuLayout.Shop
	check(S.CardMinTall - 16 - (S.GiftW + 6) >= 90 and S.GiftRowH - 62 >= 30 and S.GiftRowH - 56 - (S.GiftRowH - 62) >= 6,
		"GIFT's room: beside BUY on the narrowest tile BUY keeps 90+ px; under BUY on a phone's row it stands 30+ "
			.. "px tall with 6 px under it",
		string.format("tile BUY %d, row GIFT %d", S.CardMinTall - 16 - (S.GiftW + 6), S.GiftRowH - 62))
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nPassGiftSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
