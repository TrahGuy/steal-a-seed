--==============================================================================
-- MysteryShopSpec (2026-10-12, the owner's item 17: the Mysterious Pod, sold)
--
--   1. the products: the owner's 8 ids, counts, prices and art, by name
--   2. the honest "was": the live x1 price times the count, only when cheaper
--   3. the grant, the REAL MysteryShopService against stand-ins: the buyer's
--      pods into the Bag, the rest owed, refused whole past the cap or without
--      PolicyService's yes; a gift noted before its prompt, granted to the
--      recipient with the receipt's id in their save, never twice, to the
--      buyer if they have gone; owed pods handed over as room comes
--   4. the wiring: the receipt, the gate's own flag, the reset, OPEN ALL, the
--      Bag's button, the grid, the Shop's banner on live prices only
--   5. the words you can read (2026-10-13, backlog item 5): every rarity word
--      on an odds card light text with its ink line; the banner's light words
--      keep theirs
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local SHOP = EnchantedMistConfig.Mystery.Shop

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

local ok, err = pcall(function()
	--==========================================================================
	say("1. The products")
	--==========================================================================
	-- The owner's ids, prices and the uploads mapped BY NAME (economy details,
	-- 2026-10-12): every one an Image of the group's, none missing or twice.
	local WANT = {
		{ "mysterypod1", 3718125668, 39, 1, false, "124362936985892" },
		{ "mysterypod3", 3718125729, 99, 3, false, "112732002176388" },
		{ "mysterypod10", 3718125835, 299, 10, false, "73832859089355" },
		{ "mysterypod50", 3718126039, 1299, 50, false, "76699374080033" },
		{ "giftmysterypod1", 3718126091, 39, 1, true, "88851541577988" },
		{ "giftmysterypod3", 3718126159, 99, 3, true, "123182088890111" },
		{ "giftmysterypod10", 3718126208, 299, 10, true, "75994928904600" },
		{ "giftmysterypod50", 3718126289, 1299, 50, true, "74491754237004" },
	}
	local rows = GameConfig.Store.MysteryPods or {}
	local byKey = {}
	for _, item in ipairs(rows) do
		byKey[item.key] = item
	end
	local wrong = {}
	for _, w in ipairs(WANT) do
		local item = byKey[w[1]]
		if not (item and item.product == w[2] and item.robux == w[3] and item.count == w[4]
			and (item.gift == true) == w[5] and item.kind == "mysterypod" and item.icon == "rbxassetid://" .. w[6]) then
			table.insert(wrong, w[1])
		end
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
	scan(rows)
	check(#rows == 8 and #wrong == 0 and #twice == 0,
		"the owner's 8 products: 1/3/10/50 at 39/99/299/1299, the same as gifts, each its own art by name; no id twice",
		table.concat(wrong, ",") .. " | " .. table.concat(twice, ","))

	--==========================================================================
	say("2. The honest WAS")
	--==========================================================================
	local Banner = require(Shared:WaitForChild("MysteryShopBanner"))
	check(Banner.wasPrice(3, 39, 99) == 117 and Banner.wasPrice(10, 39, 299) == 390
			and Banner.wasPrice(50, 39, 1299) == 1950 and Banner.wasPrice(1, 39, 39) == nil
			and Banner.wasPrice(3, 39, 117) == nil and Banner.wasPrice(3, 39, 200) == nil
			and Banner.wasPrice(3, nil, 99) == nil and Banner.wasPrice(3, 39, nil) == nil
			and Banner.wasPrice(10, 16, 120) == 160,
		"WAS = the live x1 price times the count (117/390/1950 at 39), shown only when the bundle is cheaper and "
			.. "both prices are known; a regional x1 makes its own (the owner, 2026-10-12)")

	--==========================================================================
	say("3. The grant (the real MysteryShopService, stand-ins round it)")
	--==========================================================================
	local function standInPlayer(name, userId)
		return { Name = name, DisplayName = name, UserId = userId, Parent = Players }
	end
	local buyer = standInPlayer("Buyer", 90000000101)
	local friend = standInPlayer("Friend", 90000000102)
	local profiles, room, allowedFor, granted, saves = {}, {}, {}, {}, {}
	local owedCalls, saveFails = {}, {}
	local function fresh()
		table.clear(saveFails)
		profiles[buyer] = { Receipts = {}, MysteryPodsOwed = 0 }
		profiles[friend] = { Receipts = {}, MysteryPodsOwed = 0 }
		room[buyer], room[friend] = 60, 60
		allowedFor[buyer], allowedFor[friend] = true, true
		granted[buyer], granted[friend] = 0, 0
		saves[buyer], saves[friend] = 0, 0
		table.clear(owedCalls)
	end
	local PDS = {
		Get = function(p)
			return profiles[p]
		end,
		IsPersistent = function()
			return true
		end,
		UpdateDewberries = function(p, change)
			return change(profiles[p])
		end,
		AddMysteryPodsOwed = function(p, delta)
			local owed = profiles[p].MysteryPodsOwed + delta
			if owed < 0 or owed > GameConfig.Save.MaxMysteryPodsOwed then
				return nil
			end
			profiles[p].MysteryPodsOwed = owed
			table.insert(owedCalls, delta)
			return owed
		end,
		Save = function(p)
			saves[p] += 1
			return not saveFails[p]
		end,
	}
	local Carry = {
		PodRoom = function(p)
			return room[p], 60 - room[p], true
		end,
		IsHeldRestored = function()
			return true
		end,
	}
	local Pods = {
		CanGrant = function()
			return true
		end,
		Grant = function(p)
			if room[p] <= 0 then
				return false
			end
			room[p] -= 1
			granted[p] += 1
			return true, "item" .. granted[p]
		end,
		Hooks = { saveSoon = function() end },
	}
	local hooked = nil
	local Store = {
		SetMysteryGrant = function(fn)
			hooked = fn
		end,
	}
	local Wheel = {
		PolicyAllows = function(p)
			return allowedFor[p] == true
		end,
		CheckPolicy = function() end,
	}
	local module = Server:WaitForChild("MysteryShopService")
	local chunk = assert(loadstring(module.Source, "=MysteryShopService"))
	local siblings = { PlayerDataService = PDS, CarryService = Carry, MysteryPodService = Pods,
		WheelService = Wheel, StoreService = Store }
	local parent = {}
	function parent:WaitForChild(name)
		assert(siblings[name] ~= nil, "MysteryShopService asked for an unexpected sibling " .. name)
		return { __standIn = siblings[name] }
	end
	setfenv(chunk, setmetatable({
		script = { Name = "MysteryShopService", Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return require(target)
		end,
	}, { __index = getfenv(1) }))
	local Shop = chunk()
	local sent, prompts = {}, {}
	local clock = 100
	Shop.Hooks.players = function()
		return { buyer, friend }
	end
	local present = { [buyer.UserId] = buyer, [friend.UserId] = friend }
	Shop.Hooks.byUserId = function(id)
		return present[id]
	end
	Shop.Hooks.send = function(p, action, payload)
		table.insert(sent, { p = p, action = action, payload = payload })
	end
	Shop.Hooks.prompt = function(p, id)
		table.insert(prompts, { p = p, id = id })
	end
	Shop.Hooks.clock = function()
		return clock
	end
	-- `allowed` and `known` stay the module's own, over the stand-in WheelService.
	local B = Shop.Bundles

	-- The buyer's own: into the Bag, the rest owed.
	fresh()
	local okMine = Shop.Grant(buyer, B.mysterypod3, "P1")
	room[buyer] = 2
	local okTight = Shop.Grant(buyer, B.mysterypod10, "P2")
	check(okMine and okTight and granted[buyer] == 5 and profiles[buyer].MysteryPodsOwed == 8 and #owedCalls == 1
			and owedCalls[1] == 8 and saves[buyer] == 0,
		"a bundle for the buyer: into the Bag as far as it has room, the rest owed in the same step (the buyer's "
			.. "save is StoreService's)", string.format("granted %d owed %d", granted[buyer],
			profiles[buyer].MysteryPodsOwed))
	-- Refused WHOLE past the owed cap, and without PolicyService's yes.
	fresh()
	room[buyer] = 0
	profiles[buyer].MysteryPodsOwed = GameConfig.Save.MaxMysteryPodsOwed - 5
	local okCap = Shop.Grant(buyer, B.mysterypod10, "P3")
	fresh()
	allowedFor[buyer] = false
	local okPolicy = Shop.Grant(buyer, B.mysterypod1, "P4")
	check(okCap == false and okPolicy == false and granted[buyer] == 0 and #owedCalls == 0,
		"refused whole -- nothing given -- if the owed would pass its cap, or PolicyService has not said yes "
			.. "(the receipt stays open; Roblox returns the Robux)")

	-- A gift: noted before its prompt, then granted to the recipient -- their
	-- first save failing, so the receipt is retried.
	fresh()
	table.clear(sent)
	table.clear(prompts)
	Shop.AskGift(buyer, { bundle = "giftmysterypod3", recipient = friend.UserId })
	local promptedOk = #prompts == 1 and prompts[1].p == buyer and prompts[1].id == B.giftmysterypod3.product
	saveFails[friend] = true
	local okFirst = Shop.Grant(buyer, B.giftmysterypod3, "G1")
	local receiptIn = profiles[friend].Receipts[#profiles[friend].Receipts] == "G1"
	saveFails[friend] = false
	local okRetry = Shop.Grant(buyer, B.giftmysterypod3, "G1")
	local announced = 0
	for _, s in ipairs(sent) do
		if s.payload and s.payload.title == string.format(SHOP.Words.Gifted, "Buyer", "Friend", "3 Mysterious Pods") then
			announced += 1
		end
	end
	check(promptedOk and okFirst == false and okRetry and granted[friend] == 3 and granted[buyer] == 0 and receiptIn
			and saves[friend] == 2 and announced == 2,
		"a gift: the recipient noted, then the gift's prompt; its receipt gives THEM the pods with the receipt's id "
			.. "in the same step; acknowledged only once their profile saves -- the retry finds the id, gives nothing "
			.. "more, saves -- and everybody told \"Buyer gifted Friend 3 Mysterious Pods!\"",
		string.format("friend %d buyer %d saves %d told %d", granted[friend], granted[buyer], saves[friend], announced))
	-- The recipient gone before the receipt: the buyer's, with a notice.
	fresh()
	table.clear(sent)
	clock += 5
	Shop.AskGift(buyer, { bundle = "giftmysterypod1", recipient = friend.UserId })
	present[friend.UserId] = nil
	local okLeft = Shop.Grant(buyer, B.giftmysterypod1, "G2")
	present[friend.UserId] = friend
	local leftSaid = false
	for _, s in ipairs(sent) do
		if s.p == buyer and s.payload and s.payload.title == string.format(SHOP.Words.GiftLeft, "Friend",
			"a Mysterious Pod") then
			leftSaid = true
		end
	end
	check(okLeft and granted[buyer] == 1 and granted[friend] == 0 and leftSaid,
		"the recipient gone before the receipt: the buyer gets the pods, and is told why")
	-- Never to yourself, nor to nobody, nor to one PolicyService has not allowed.
	fresh()
	table.clear(prompts)
	table.clear(sent)
	clock += 5
	Shop.AskGift(buyer, { bundle = "giftmysterypod1", recipient = buyer.UserId })
	clock += 5
	Shop.AskGift(buyer, { bundle = "giftmysterypod1", recipient = 90000000999 })
	clock += 5
	allowedFor[friend] = false
	Shop.AskGift(buyer, { bundle = "giftmysterypod1", recipient = friend.UserId })
	local codes = {}
	for _, s in ipairs(sent) do
		if s.action == SHOP.GiftReply then
			table.insert(codes, s.payload.code)
		end
	end
	check(#prompts == 0 and table.concat(codes, ",") == "NO_PLAYER,NO_PLAYER,RESTRICTED",
		"no gift prompt for yourself, nobody here, or a player PolicyService has not allowed",
		table.concat(codes, ","))
	-- Owed, handed over as room comes.
	fresh()
	profiles[buyer].MysteryPodsOwed = 8
	room[buyer] = 3
	local handed = Shop.DeliverOwed(buyer)
	check(handed == 3 and granted[buyer] == 3 and profiles[buyer].MysteryPodsOwed == 5,
		"owed pods go into the Bag as room comes, the count coming down with them")

	--==========================================================================
	say("4. The wiring")
	--==========================================================================
	local store = strip(Server:WaitForChild("StoreService").Source)
	local wheel = strip(Server:WaitForChild("WheelService").Source)
	local data = strip(Server:WaitForChild("PlayerDataService").Source)
	local schema = strip(Server:WaitForChild("ProfileSchema").Source)
	local plant = strip(Server:WaitForChild("PlantService").Source)
	local reveal = strip(Scripts:WaitForChild("MysteryRevealUI").Source)
	local loadout = strip(Scripts:WaitForChild("LoadoutUI").Source)
	local shopUi = strip(Scripts:WaitForChild("ShopUI").Source)
	local panel = strip(Shared:WaitForChild("InventoryPanel").Source)
	local banner = strip(Shared:WaitForChild("MysteryShopBanner").Source)
	check(has(store, "for _, item in ipairs(STORE.MysteryPods or {}) do") and has(store, "elseif item.kind == \"mysterypod\" then")
			and has(store, "return fn(player, item, purchaseId)") and has(store, "if not grant(player, item, purchaseId) then")
			and hooked == nil and has(strip(module.Source), "StoreService.SetMysteryGrant(MysteryShopService.Grant)"),
		"StoreService indexes the bundles and hands their receipts to MysteryShopService (its ledger and the "
			.. "buyer's save still its own)")
	check(has(wheel, "put(player, POD_POLICY, if paidOk[player] == true then true else nil)")
			and has(wheel, "function WheelService.PolicyAllows(player: Player): boolean\n\treturn paidOk[player] == true")
			and has(wheel, "local function paidAllowed(player: Player): boolean\n\treturn paidOk[player] == true and productLive()"),
		"THE GATE: PolicyService's own fail-closed answer, apart from the wheel's switch, on the pods' own flag "
			.. "(the wheel's own rule unchanged)")
	check(has(data, "MysteryPodsOwed = math.max(0, math.floor(tonumber(profile.MysteryPodsOwed) or 0)),")
			and has(schema, "MysteryPodsOwed = 0,")
			and has(schema, "p.MysteryPodsOwed = math.floor(number(raw.MysteryPodsOwed, 0, 0, SAVE.MaxMysteryPodsOwed))"),
		"owed pods are saved (0 on an old save, clamped) and kept by a progress reset -- paid for, never delivered")
	check(has(plant, "function PlantService.OpenAllMystery(player: Player): (boolean, string, number)")
			and has(plant, "MysteryPodService.ReserveSpan(player, Workspace:GetServerTimeNow(), OPEN.GridSeconds)")
			and has(plant, "MysteryPodService.TellOpenAll(player, group.outcomes, startAt, seconds)")
			and has(plant, "if due and now >= due and type(row.Item) == \"string\" and MysteryPodService.IsShell(row.Id) then")
			and has(plant, "elseif action == BAG.OpenAll then")
			and has(plant, "if mystery and not group then\n\t\t\t\tMysteryPodService.Unreserve(player, drawAt, drawLen)"),
		"OPEN ALL: every READY Mysterious Pod, one booking for one grid, each hatched -- and spent -- once")
	check(has(panel, "local showOpen = readyShells >= 2") and has(loadout, "remote:FireServer(HATCH_BAG.OpenAll)")
			and has(loadout, "readyShells = podsNow.shellsReady,")
			and has(reveal, "payload.phase == \"hatch\" or payload.phase == OPEN.Phase")
			and has(reveal, "local run = if payload.phase == OPEN.Phase then playGrid else play"),
		"the Bag offers OPEN ALL with two or more ready; the grid waits its turn like a draw")
	check(has(shopUi, "local podBanner = MysteryShopBanner.build(grid, body, Z + 1, -1)")
			and has(shopUi, "podBanner.setOpen(want)")
			and has(banner, "tilesRow.Visible = yes") and has(banner, "return player:GetAttribute(SHOP.PolicyAttribute) == true")
			and has(banner, "RobuxPrice.watch(\"product\", item.product,")
			and not string.find(banner, "%.robux") and not has(banner, "GetProductInfo")
			and has(banner, "MistOddsView.card(slot, entry, z + 2, CARD_H, moving, fx, cardViews)")
			and has(banner, "oddsView = MistOddsView.build(oddsHolder, z + 42)")
			and has(banner, "channel:FireServer(SHOP.GiftAction, { bundle = giftFor.key, recipient = other.UserId })"),
		"the Shop's banner, first on the page: the six inside with their odds and ODDS's full page before any buy, "
			.. "this player's live prices only, offer and GIFT shown only on PolicyService's yes")

	--==========================================================================
	say("5. The words you can read (2026-10-13, backlog item 5)")
	--==========================================================================
	-- The owner: "some texts is not readable due to color overlap". Every
	-- rarity word on an odds card is light text by MenuKit's own rule, with its
	-- ink line kept; so are the banner's tagline, WAS prices and gift refusal
	-- (MenuKit.ink SETS a colour: ink(label, INK) had made the words near-black).
	local MenuKit = require(Shared:WaitForChild("MenuKit"))
	local MistOddsView = require(Shared:WaitForChild("MistOddsView"))
	local dim = {}
	for rarity in pairs(GameConfig.RarityColor) do
		local c = MistOddsView.wordColour(rarity)
		if not MenuKit.isLight(c) then
			table.insert(dim, string.format("%s (%d, %d, %d)", rarity, c.R * 255, c.G * 255, c.B * 255))
		end
	end
	table.sort(dim)
	local odds = strip(Shared:WaitForChild("MistOddsView").Source)
	check(#dim == 0
			and has(odds, 'local rarity = MenuKit.text(face, "Rarity", 13, MistOddsView.wordColour(entry.Rarity), z + 5)')
			and has(odds, "MenuKit.keepInk(rarity).Thickness = 1.5"),
		"every rarity word on an odds card is light text with its ink line", table.concat(dim, ", "))
	check(has(banner, "MenuKit.keepInk(tagline).Thickness = 1.5") and has(banner, "MenuKit.keepInk(was).Thickness = 1.5")
			and has(banner, "MenuKit.keepInk(status).Thickness = 1.5")
			and has(banner, 'MenuKit.text(tileFrame, "Was", 16, Color3.fromRGB(226, 230, 242), z + 4)')
			and not has(banner, "MenuKit.ink(tagline") and not has(banner, "MenuKit.ink(was")
			and not has(banner, "MenuKit.ink(status"),
		"the banner's tagline, WAS prices and gift refusal are light words that keep their ink line")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMysteryShopSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
