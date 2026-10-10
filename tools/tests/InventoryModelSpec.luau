--!nocheck
--==============================================================================
-- Steal a Seed :: InventoryModelSpec
--
-- What the compact Bag shows, as data (InventoryModel), and what a press meant
-- (PressGesture) -- 2026-10-03, the owner's compact Bag + free hotbar. Edit
-- mode, pure: stand-in Tools are tables with GetAttribute.
--
--   1. no pod's name, key, search words, picture or place in the order depends
--      on the species inside it -- across every species list -- and a plant
--      still in its roll is its pod
--   2. collect: rows with their live Tool by name, restoring rows, a Tool not
--      yet told its id, weapons, tickets, the trail, the RevealAt cache
--   3. groups: counts, splits (species id, size, favourite), the bar left out,
--      a phone's slots 6-0 with a badge; counts, pick, filter, storage
--   4. PressGesture's table, and dropTarget
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local InventoryModel = require(Shared:WaitForChild("InventoryModel"))
local PressGesture = require(Shared:WaitForChild("PressGesture"))
local HotbarSlots = require(Shared:WaitForChild("HotbarSlots"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
-- The owner's 25 pods, one per plant (2026-10-09): their picture is their own.
local PodForms = require(Shared:WaitForChild("PodForms"))

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

local NOW = 5000
local function tool(attrs)
	return { GetAttribute = function(_, name)
		return attrs[name]
	end, _attrs = attrs }
end
local function plantTool(species, tier, hatched, item, revealAt)
	return tool({ SpeciesId = species, CarryingKg = tier, Hatched = hatched, ItemId = item, RevealAt = revealAt })
end
local function input(fields)
	local i = { held = {}, tools = {}, weapons = {}, tickets = 0, favourites = {}, sealedUntil = {}, now = NOW }
	for k, v in pairs(fields) do
		i[k] = v
	end
	return i
end
local function podItem(speciesId, tier)
	return { ref = "i:1", kind = "pod", speciesId = speciesId, tier = tier, hatched = false, sealed = false,
		restoring = false, count = 1, worn = false, favourite = false, order = 1 }
end
local function faceKey(f)
	return table.concat({ f.name, f.variant, f.visual, tostring(f.art.speciesId), tostring(f.art.tier), f.search,
		f.category }, "|")
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. A POD NEVER SAYS WHAT IS INSIDE IT
	--==========================================================================
	say("-- a pod never says what is inside it --")
	local all = {}
	for _, list in ipairs({ SeedData.Species, SeedData.SecretSpecies, SeedData.RainSpecies }) do
		for _, s in ipairs(list) do
			table.insert(all, s)
		end
	end
	local byVisual = {}
	local leaks, mentions, ownless = {}, {}, {}
	for _, s in ipairs(all) do
		for tier = 1, SeedData.TierCount do
			local f = InventoryModel.face(podItem(s.Id, tier))
			local seen = byVisual[f.visual]
			if seen and seen ~= faceKey(f) then
				table.insert(leaks, s.Id .. "@" .. tier)
			end
			byVisual[f.visual] = seen or faceKey(f)
			local words = string.lower(f.name .. " " .. f.search .. " " .. f.variant)
			local named = string.find(words, string.lower(s.Name), 1, true) ~= nil
			-- An owner's pod (2026-10-09) is drawn as its own species' pod, so its picture
			-- key holds its id; its words still never do.
			for token in string.gmatch(f.visual, "[^|:]+") do
				if token == s.Id and not PodForms.Has(s.Id) then
					named = true
				end
			end
			if PodForms.Has(s.Id) and not (f.art.speciesId == s.Id and f.visual == "pod|p:" .. s.Id .. "|" .. tier) then
				table.insert(ownless, s.Id .. "@" .. tier)
			end
			if named then
				table.insert(mentions, s.Id)
			end
		end
	end
	check(#leaks == 0, "every pod with the same shell has the same face, key and picture, whatever is inside",
		table.concat(leaks, ","))
	check(#mentions == 0, "no pod's name, search words or variant names its species, nor any key but an owner's pod's",
		table.concat(mentions, ","))
	check(#ownless == 0, "each of the owner's 25 pods is drawn as its own species' pod, at its size (2026-10-09)",
		table.concat(ownless, ","))
	-- One pod per plant (2026-10-09): two species are two pictures, so two tiles; two of one species and
	-- size are one tile of two, sorted by item id alone.
	local greenhollow = SeedData.InBiome("greenhollow")
	local a = InventoryModel.collect(input({ held = {
		{ Id = greenhollow[1].Id, Tier = 2, Hatched = false, Item = "7" },
		{ Id = greenhollow[2].Id, Tier = 2, Hatched = false, Item = "3" },
	} }))
	local g1 = InventoryModel.groups(a, HotbarSlots.empty(), 10)
	check(#g1 == 2 and g1[1].count == 1 and g1[2].count == 1,
		"two different species' pods are two tiles, each its own pod", #g1)
	local same = InventoryModel.collect(input({ held = {
		{ Id = greenhollow[1].Id, Tier = 2, Hatched = false, Item = "7" },
		{ Id = greenhollow[1].Id, Tier = 2, Hatched = false, Item = "3" },
	} }))
	local g2 = InventoryModel.groups(same, HotbarSlots.empty(), 10)
	check(#g2 == 1 and g2[1].count == 2, "two of one species at one size are one tile of two", #g2)
	local f1 = InventoryModel.face(podItem("snarlbloom", 1))
	check(f1.name == "Secret pod" and f1.category == "pods", "a Secret pod is called a Secret pod", f1.name)
	local rain = InventoryModel.face(podItem("tempestoak", 1))
	local rain2 = InventoryModel.face(podItem("thundermaw", 1))
	check(rain.name == "Thunderstorm pod" and faceKey(rain) == faceKey(rain2), "a Rain pod says which pod, not which creature",
		rain.name)
	-- A plant still in its roll is its pod.
	local rolling = InventoryModel.collect(input({ held = { { Id = "nubkin", Tier = 3, Hatched = true, Item = "4" } },
		tools = { plantTool("nubkin", 3, true, "4", NOW + 2) } }))
	check(rolling[1].kind == "pod" and rolling[1].sealed and InventoryModel.face(rolling[1]).category == "pods",
		"a hatched plant whose roll still runs is drawn as a pod")
	local unrolled = InventoryModel.collect(input({ held = { { Id = "nubkin", Tier = 3, Hatched = true, Item = "4" } },
		tools = { plantTool("nubkin", 3, true, "4", NOW - 1) } }))
	check(unrolled[1].kind == "plant" and InventoryModel.face(unrolled[1]).name == SeedData.Get("nubkin").Name,
		"once its roll ends it is the plant")
	-- Restoring mid-roll: the cache keeps it a pod.
	local cache = {}
	InventoryModel.collect(input({ held = { { Id = "nubkin", Tier = 3, Hatched = true, Item = "4" } },
		tools = { plantTool("nubkin", 3, true, "4", NOW + 2) }, sealedUntil = cache }))
	check(cache["4"] == NOW + 2, "the RevealAt seen on a Tool is remembered by item id")
	local restoring = InventoryModel.collect(input({ held = { { Id = "nubkin", Tier = 3, Hatched = true, Item = "4" } },
		sealedUntil = cache }))
	check(restoring[1].restoring and restoring[1].kind == "pod",
		"a plant restoring after a respawn mid-roll is still its pod, never its species")
	-- Plants are grouped by species id: Puddlepod and Colossal Puddlepod share a name.
	local pp = InventoryModel.collect(input({ held = {
		{ Id = "puddlepod", Tier = 1, Hatched = true, Item = "1" },
		{ Id = "puddlepod_colossal", Tier = 7, Hatched = true, Item = "2" },
	}, tools = { plantTool("puddlepod", 1, true, "1"), plantTool("puddlepod_colossal", 7, true, "2") } }))
	check(#InventoryModel.groups(pp, HotbarSlots.empty(), 10) == 2, "same name, different species: two tiles")

	--==========================================================================
	-- 2. COLLECT
	--==========================================================================
	say("-- collect --")
	local bat = WeaponData.Items[1].Id
	local trap
	for _, w in ipairs(WeaponData.Items) do
		if w.Category == "trap" then
			trap = trap or w.Id
		end
	end
	local named = plantTool("nubkin", 1, true, "1")
	local unstamped = plantTool("nubkin", 1, true, nil)
	local batTool = tool({ WeaponId = bat })
	local ticketTool = tool({ SpinTicket = true, TicketCount = 3 })
	local items = InventoryModel.collect(input({
		held = {
			{ Id = "nubkin", Tier = 1, Hatched = true, Item = "1" },
			{ Id = "nubkin", Tier = 1, Hatched = true, Item = "2" },
			{ Id = "nubkin", Tier = 1, Hatched = true, Item = "3" },
			{ Id = "toadcap", Tier = 2, Hatched = false, Item = "9" },
		},
		tools = { named, unstamped, batTool, ticketTool },
		weapons = { [bat] = true, [trap] = true, gone_bat = true },
		tickets = 3,
		trailOwned = true,
		favourites = { ["i:1"] = true },
	}))
	local by = {}
	for _, item in ipairs(items) do
		by[item.ref or (item.kind .. tostring(item.tool))] = item
	end
	check(#items == 8, "four rows, two weapons the shelf knows, the tickets and the trail", #items)
	check(by["i:1"] and by["i:1"].tool == named and not by["i:1"].restoring and by["i:1"].favourite,
		"a row with its Tool by name, favourited")
	local paired, restoringCount = 0, 0
	for _, item in ipairs(items) do
		if item.tool == unstamped then
			paired += 1
			check(item.ref == nil, "a Tool not yet told its id stands for a row of its kind, and cannot be assigned")
		end
		if item.restoring then
			restoringCount += 1
		end
	end
	check(paired == 1 and restoringCount == 2, "it is counted once; the rows with no Tool are restoring",
		restoringCount)
	check(by["w:" .. bat] and by["w:" .. bat].tool == batTool and by["w:" .. trap] and by["w:" .. trap].tool == nil,
		"weapons: the bat out has its Tool, the trap not out has none")
	check(by.ticket and by.ticket.count == 3 and by.ticket.tool == ticketTool, "the ticket stack, with its balance")
	local trailItem
	for _, item in ipairs(items) do
		if item.kind == "trail" then
			trailItem = item
		end
	end
	check(trailItem ~= nil and trailItem.ref == nil, "the trail is listed, and is never assignable")
	local before = input({ tools = { plantTool("nubkin", 1, true, "5") } })
	before.held = nil
	local early = InventoryModel.collect(before)
	check(#early == 1 and early[1].ref == "i:5" and not early[1].restoring, "before the profile: the live Tools")

	--==========================================================================
	-- 3. GROUPS, COUNTS, PICK, FILTER, STORAGE
	--==========================================================================
	say("-- groups --")
	local rows = {}
	local tools = {}
	for i = 1, 4 do
		table.insert(rows, { Id = "nubkin", Tier = 1, Hatched = true, Item = tostring(i) })
		table.insert(tools, plantTool("nubkin", 1, true, tostring(i)))
	end
	table.insert(rows, { Id = "nubkin", Tier = 2, Hatched = true, Item = "5" })
	table.insert(tools, plantTool("nubkin", 2, true, "5"))
	local set = InventoryModel.collect(input({ held = rows, tools = tools, favourites = { ["i:4"] = true },
		weapons = { [bat] = true }, tickets = 12 }))
	local barTen = HotbarSlots.empty()
	barTen[1] = "w:" .. bat
	barTen[4] = "i:1"
	barTen[7] = "i:2"
	local desk = InventoryModel.groups(set, barTen, 10, nil, nil)
	local keys = {}
	for _, g in ipairs(desk) do
		keys[#keys + 1] = g.key .. "x" .. g.count
	end
	check(#desk == 4, "desktop: bar items left out; tier 1 x1, the favourite, tier 2, the tickets", table.concat(keys, " "))
	check(desk[1].favourite and desk[1].count == 1, "favourites come first")
	local phone = InventoryModel.groups(set, barTen, 5, nil, nil)
	local badged
	for _, g in ipairs(phone) do
		if g.badge then
			badged = g
		end
	end
	check(badged ~= nil and badged.badge == 7 and badged.count == 1, "phone: slot 7's item is in the grid with its badge")
	-- EVERY BAR ITEM IN THE GRID TOO (2026-10-10, Michael on v1047: "Maybe they
	-- should appear in the bag as well but with a frame and icon for the hotbar
	-- number"; the owner approved): LoadoutUI asks with shown = 0, so each slotted
	-- item is its own tile wearing its slot's number.
	local all = InventoryModel.groups(set, barTen, 0, nil, nil)
	local badges = {}
	for _, g in ipairs(all) do
		if g.badge then
			table.insert(badges, g.badge)
		end
	end
	table.sort(badges)
	check(table.concat(badges, ",") == "1,4,7", "shown 0: the bat (slot 1), slot 4's and slot 7's items are tiles with their badges",
		table.concat(badges, ","))
	local loadout = ""
	for _, s in ipairs(game:GetService("StarterPlayer"):GetDescendants()) do
		if s.Name == "LoadoutUI" and s:IsA("LocalScript") then
			loadout = s.Source
		end
	end
	-- (2026-10-10: the player's sort follows `held` as a sixth argument; SortSpec.)
	check(string.find(loadout, "InventoryModel.groups(view.items, shownBar(), 0, HotbarSlots.refOfTool(held), held", 1, true)
			~= nil, "LoadoutUI asks for every bar item in the grid (shown 0)")
	local counts = InventoryModel.counts(set)
	check(counts.all == 7 and counts.plants == 5 and counts.equipment == 1 and counts.tickets == 12,
		"counts include the bar; Spin Tickets is the balance", counts.all)
	local nub1 = nil
	for _, g in ipairs(desk) do
		if g.key == "plant|nubkin|1" then
			nub1 = g
		end
	end
	check(nub1 and nub1.count == 1 and InventoryModel.pick(nub1).ref == "i:3", "pick: the lowest id not on the bar")
	local fullGroup = InventoryModel.groups(set, HotbarSlots.empty(), 10)
	local all1 = nil
	for _, g in ipairs(fullGroup) do
		if g.key == "plant|nubkin|1" then
			all1 = g
		end
	end
	check(all1 and all1.count == 3 and InventoryModel.pick(all1, "i:2").ref == "i:2"
		and InventoryModel.pick(all1).ref == "i:1", "pick: the copy in hand if it is in the group, else the lowest id")
	check(#InventoryModel.filter(fullGroup, "plants", "", false) == 3 and #InventoryModel.filter(fullGroup, "tickets", "", false) == 1
		and #InventoryModel.filter(fullGroup, "all", "", true) == 1, "category and heart filters")
	local nubName = string.lower(SeedData.Get("nubkin").Name)
	check(#InventoryModel.filter(fullGroup, "all", "  " .. string.upper(nubName) .. " ", false) == 3
		and #InventoryModel.filter(fullGroup, "all", "zzz", false) == 0
		and #InventoryModel.filter(fullGroup, "all", "%", false) == 0,
		"search: case-insensitive, trimmed, plain (no pattern)")
	local podSet = InventoryModel.collect(input({ held = { { Id = "nubkin", Tier = 2, Hatched = false, Item = "1" } } }))
	check(#InventoryModel.filter(InventoryModel.groups(podSet, HotbarSlots.empty(), 10), "all", nubName, false) == 0,
		"search never finds a pod by the species inside it")
	local s1 = InventoryModel.storage(4, false, 24)
	local s2, full2 = InventoryModel.storage(23, true, 24)
	local s3 = InventoryModel.storage(23, true, 24, 1)
	check(s1 == "Plant storage: 4/24" and s2 == "Plant storage: 23 stored + 1 carried / 24" and full2,
		"the storage line, with a carried pod", s2)
	check(string.find(s3, "1 wheel prize waiting for room", 1, true) ~= nil, "and a prize owed for want of room", s3)
	local details = InventoryModel.details(podSet[1], InventoryModel.face(podSet[1]), 1, nil, false)
	local text = {}
	for _, line in ipairs(details) do
		table.insert(text, line.key .. "=" .. line.value)
	end
	check(not string.find(string.lower(table.concat(text, " ")), nubName, 1, true),
		"a pod's details never name the species", table.concat(text, " "))
	local ticketDetails = InventoryModel.details(by.ticket, InventoryModel.face(by.ticket), 1, 3, false)
	check(ticketDetails[1].value == "x3" and InventoryModel.face(by.ticket).name ~= PlantInfo.PodTitle,
		"the ticket is never an Unhatched pod")

	--==========================================================================
	-- 4. PRESS GESTURES
	--==========================================================================
	say("-- press gestures --")
	local V = Vector2.new
	local p = PressGesture.begin("touch", V(100, 100), V(0, 0), 0, true)
	check(PressGesture.release(p, V(104, 103), V(0, 0), 0.2) == "tap", "touch: a short press inside the slop is a tap")
	p = PressGesture.begin("touch", V(100, 100), V(0, 0), 0, true)
	check(PressGesture.step(p, V(100, 100), V(0, 0), 0.5) == "long"
		and PressGesture.release(p, V(100, 100), V(0, 0), 0.6) == "none", "touch: held 0.45 s is a long press, no tap")
	p = PressGesture.begin("touch", V(100, 100), V(0, 0), 0, true)
	check(PressGesture.step(p, V(112, 100), V(0, 0), 0.1) == "scroll"
		and PressGesture.step(p, V(100, 100), V(0, 0), 0.6) == "scroll"
		and PressGesture.release(p, V(100, 100), V(0, 0), 0.7) == "none", "touch: past 10 px is a scroll, and stays one")
	p = PressGesture.begin("touch", V(100, 100), V(0, 0), 0, true)
	check(PressGesture.step(p, V(101, 100), V(0, 6), 0.1) == "scroll", "touch: the canvas moving 4+ px is a scroll")
	p = PressGesture.begin("touch", V(100, 100), V(0, 0), 0, true)
	check(PressGesture.step(p, V(130, 100), V(0, 0), 0.1) ~= "drag", "touch never drags")
	p = PressGesture.begin("mouse", V(100, 100), V(0, 0), 0, true)
	check(PressGesture.step(p, V(109, 100), V(0, 0), 0.1) == "drag", "mouse: 8 px on something draggable is a drag")
	p = PressGesture.begin("mouse", V(100, 100), V(0, 0), 0, false)
	check(PressGesture.step(p, V(109, 100), V(0, 0), 2) == "pressing"
		and PressGesture.release(p, V(120, 100), V(0, 0), 2) == "none",
		"mouse: never a long press; wandering off something not draggable is nothing")
	p = PressGesture.begin("pad", V(0, 0), V(0, 0), 0, true)
	check(PressGesture.release(p, nil, nil, 5) == "tap", "pad: always a tap")
	local slots = {
		{ x = 0, y = 0, w = 64, h = 64 }, { x = 68, y = 0, w = 64, h = 64 }, { x = 0, y = 0, w = 0, h = 0 },
	}
	local bagRect = { { x = 0, y = 100, w = 300, h = 200 } }
	local kind, index = PressGesture.dropTarget(V(66, 30), slots, bagRect, 2)
	check(kind == "slot" and index ~= nil, "a drop in the gap between slots belongs to a slot")
	kind, index = PressGesture.dropTarget(V(100, 150), slots, bagRect, 2)
	check(kind == "bag" and index == nil, "a drop on the open Bag is the Bag")
	kind = PressGesture.dropTarget(V(500, 500), slots, bagRect, 2)
	check(kind == nil, "anywhere else cancels")

	--==========================================================================
	-- 5. PODS HATCH IN THE BAG (2026-10-09)
	--==========================================================================
	say("\n-- 5. pods hatch in the Bag --")
	local HATCH_AT = GameConfig.HatchInBag.Attribute
	local function podTool(item, tier, hatchAt)
		return tool({ SpeciesId = "nubkin", CarryingKg = tier, Hatched = false, ItemId = item, [HATCH_AT] = hatchAt })
	end
	local items = InventoryModel.collect(input({
		held = {
			{ Id = "nubkin", Tier = 1, Hatched = false, Item = "71", HatchAt = NOW - 10 },
			{ Id = "nubkin", Tier = 1, Hatched = false, Item = "72", HatchAt = NOW + 200 },
			{ Id = "nubkin", Tier = 1, Hatched = false, Item = "73", HatchAt = NOW + 65 },
			{ Id = "nubkin", Tier = 1, Hatched = false, Item = "74", HatchAt = NOW + 9999 },
		},
		tools = { podTool("71", 1, NOW - 10), podTool("72", 1, NOW + 200), podTool("73", 1, NOW + 65) },
	}))
	local byItem = {}
	for _, it in ipairs(items) do
		byItem[tostring(it.ref)] = it
	end
	check(byItem["i:71"].ready == true and byItem["i:71"].hatchAt == NOW - 10 and byItem["i:72"].ready == false
			and byItem["i:74"].restoring == true and byItem["i:74"].hatchAt == NOW + 9999,
		"a pod's deadline comes off its Tool, or its row while it is put back; READY once it has passed")
	local groups = InventoryModel.groups(items, HotbarSlots.empty(), 10)
	local readyGroup, growGroup = nil, nil
	for _, g in ipairs(groups) do
		if string.find(g.key, "|ready", 1, true) then
			readyGroup = g
		elseif string.find(g.key, "|grow", 1, true) then
			growGroup = g
		end
	end
	check(readyGroup ~= nil and growGroup ~= nil and readyGroup.count == 1 and growGroup.count == 3,
		"the same shell splits into a READY tile and a growing one", #groups)
	local isReady, left = InventoryModel.podState(growGroup, NOW)
	local picked = InventoryModel.pick(growGroup)
	check(isReady == false and left == 65 and picked ~= nil and picked.ref == "i:73",
		"a growing tile counts down the pod due first, and a press means that pod", tostring(left))
	local readyNow = InventoryModel.podState(readyGroup, NOW)
	check(readyNow == true and InventoryModel.readyCount(items, NOW) == 1, "the READY tile says so, and HATCH ALL counts 1")
	check(InventoryModel.clock(45) == "0:45" and InventoryModel.clock(245) == "4:05" and InventoryModel.clock(4350) == "1:12:30"
			and InventoryModel.clock(0.2) == "0:01",
		"the countdown's words: 0:45, 4:05, 1:12:30, and never 0:00 while time is left")
	local face = InventoryModel.face(byItem["i:73"])
	local lines = InventoryModel.details(byItem["i:73"], face, nil, nil, false, NOW)
	local hatches = nil
	for _, line in ipairs(lines) do
		if line.key == "Hatches" then
			hatches = line.value
		end
	end
	local readyLines = InventoryModel.details(byItem["i:71"], InventoryModel.face(byItem["i:71"]), nil, nil, false, NOW)
	local readyWord = nil
	for _, line in ipairs(readyLines) do
		if line.key == "Hatches" then
			readyWord = line.value
		end
	end
	check(hatches == "In 1:05" and readyWord == "Ready now", "the details say when it hatches", tostring(hatches))
	local podText, podsFull, known = InventoryModel.podStorage(12, false, 60)
	local carried = InventoryModel.podStorage(59, true, 60)
	check(podText == "Pods: 12/60" and not podsFull and known and carried == "Pods: 59+1/60"
			and select(2, InventoryModel.podStorage(59, true, 60)) == true,
		"the pod room's line: Pods 12/60, and a carried pod's place in it", podText)
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nInventoryModelSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
