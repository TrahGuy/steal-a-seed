--!nocheck
--==============================================================================
-- Steal a Seed :: HotbarSlotsSpec
--
-- The freely assignable hotbar's one grammar (2026-10-03, the owner's compact
-- Bag + free hotbar), pure functions only: the refs, what a profile owns, the
-- bar a profile starts with, every way a saved or sent bar is cleaned, the
-- load-time fill, prune, the client's edits and where an arrival goes. Edit
-- mode, no Instances but stand-in tables.
--
-- Not here: the profile, the remote and the rate limit (InventorySpec), and the
-- strip and the Bag that draw it (HotbarSpec, InventoryModelSpec).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local HotbarSlots = require(Shared:WaitForChild("HotbarSlots"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))
local Server = game:GetService("ServerScriptService"):WaitForChild("SeedGameServer")

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
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return found and found.Source
	end)
	return if ok and src then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
local function show(bar)
	local parts = {}
	for i = 1, 10 do
		parts[i] = if bar[i] == "" then "_" else tostring(bar[i])
	end
	return table.concat(parts, ",")
end
local function bar(...)
	local b = HotbarSlots.empty()
	for i, ref in ipairs({ ... }) do
		b[i] = ref
	end
	return b
end

-- The first bat, the last bat and the first trap in shop order.
local bats, traps = {}, {}
for _, item in ipairs(WeaponData.Items) do
	table.insert(if item.Category == "bat" then bats else traps, item.Id)
end
local BAT1, BATN, TRAP1 = bats[1], bats[#bats], traps[1]

local function profile(fields)
	local p = {
		Held = {},
		Weapons = {},
		EquippedBat = "",
		EquippedTrap = "",
		WheelEarned = 0,
	}
	for k, v in pairs(fields or {}) do
		p[k] = v
	end
	return p
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE GRAMMAR
	--==========================================================================
	say("-- the grammar --")
	check(HotbarSlots.Slots == 10 and GameConfig.Inventory.Slots == 10, "ten slots, numbered 1-9 and 0")
	check(HotbarSlots.ItemAttribute == GameConfig.Attributes.ItemId, "the item attribute is GameConfig's ItemId")
	check(HotbarSlots.WeaponAttribute == WeaponModel.ItemAttribute, "the weapon attribute is WeaponModel's")
	check(has(sourceOf(Server, "WheelService"), 'local TICKET = "' .. HotbarSlots.TicketAttribute .. '"'),
		"the ticket attribute is WheelService's own")
	local kind, id = HotbarSlots.parse("i:12")
	check(kind == "item" and id == "12", "i:<Item> is one plant or pod", kind)
	kind, id = HotbarSlots.parse("w:" .. BAT1)
	check(kind == "weapon" and id == BAT1, "w:<id> is one bat or trap")
	check(HotbarSlots.parse("ticket") == "ticket", "ticket is the stack")
	kind, id = HotbarSlots.parse("+trap")
	check(kind == "placeholder" and id == "trap", "+trap is a faint slot waiting for a trap")
	local junk = { "", "i:", "w:", "x:1", "I:1", "tickets", "+plant", 7, true, {}, string.rep("i", 33) }
	local none = true
	for _, ref in ipairs(junk) do
		if HotbarSlots.parse(ref) ~= nil then
			none = false
		end
	end
	check(none, "junk, an empty id, an unknown prefix and a 33-character string parse to nothing")
	check(HotbarSlots.parse("i:" .. string.rep("9", 30)) == "item" and HotbarSlots.parse("i:" .. string.rep("9", 31)) == nil,
		"32 characters is the longest ref")
	check(HotbarSlots.categoryOf("w:" .. BAT1) == "bat" and HotbarSlots.categoryOf("w:" .. TRAP1) == "trap"
		and HotbarSlots.categoryOf("ticket") == "ticket" and HotbarSlots.categoryOf("i:4") == "item"
		and HotbarSlots.categoryOf("+bat") == "bat" and HotbarSlots.categoryOf("w:no_such_bat") == nil,
		"categories: bat, trap, ticket, item; a weapon the shelf forgot has none")

	--==========================================================================
	-- 2. WHAT A PROFILE OWNS
	--==========================================================================
	say("-- owned --")
	local p = profile({
		Held = { { Id = "x", Tier = 1, Item = "3" }, { Id = "y", Tier = 2, Item = "9" }, { Id = "z", Tier = 1 } },
		Weapons = { [BAT1] = true, [TRAP1] = true, no_such_bat = true, [BATN] = false },
		WheelEarned = 2,
	})
	local o = HotbarSlots.owned(p)
	check(o["i:3"] and o["i:9"] and o["w:" .. BAT1] and o["w:" .. TRAP1] and o.ticket,
		"every row's Item, every owned weapon, and the ticket stack")
	check(not o["w:no_such_bat"] and not o["w:" .. BATN], "not a weapon the shelf forgot, nor one saved false")
	local count = 0
	for _ in pairs(o) do
		count += 1
	end
	check(count == 5, "a row with no Item owns no ref", count)
	check(not HotbarSlots.owned(profile({ WheelEarned = 0 / 0 })).ticket
		and not HotbarSlots.owned(profile({ WheelEarned = 0.5 })).ticket
		and not HotbarSlots.owned(profile({ WheelEarned = "3" })).ticket,
		"NaN, a fraction under one and a string are no tickets")
	check(next(HotbarSlots.owned(nil)) == nil, "nil owns nothing")
	check(HotbarSlots.owns(p, "i:9") and not HotbarSlots.owns(p, "i:10") and HotbarSlots.owns(p, "ticket")
		and not HotbarSlots.owns(p, "+bat"), "owns answers the same, and a placeholder is never owned")

	--==========================================================================
	-- 3. SEED
	--==========================================================================
	say("-- seed --")
	check(show(HotbarSlots.seed(nil)) == "+bat,+trap,+ticket,_,_,_,_,_,_,_",
		"a new player: three faint slots, the rest empty", show(HotbarSlots.seed(nil)))
	local equipped = profile({ Weapons = { [BAT1] = true, [BATN] = true, [TRAP1] = true },
		EquippedBat = BAT1, EquippedTrap = TRAP1, WheelEarned = 1 })
	local seeded = HotbarSlots.seed(equipped)
	check(seeded[1] == "w:" .. BAT1 and seeded[2] == "w:" .. TRAP1 and seeded[3] == "ticket" and seeded[4] == "",
		"the equipped bat, the equipped trap, the tickets", show(seeded))
	local unequipped = profile({ Weapons = { [BAT1] = true, [BATN] = true }, WheelEarned = 0 })
	seeded = HotbarSlots.seed(unequipped)
	check(seeded[1] == "w:" .. BATN and seeded[2] == "+trap" and seeded[3] == "+ticket",
		"owning bats with none out: the last owned in shop order; no trap and no tickets stay faint", show(seeded))
	local wrong = profile({ Weapons = { [BAT1] = true }, EquippedBat = TRAP1, EquippedTrap = BAT1 })
	seeded = HotbarSlots.seed(wrong)
	check(seeded[1] == "w:" .. BAT1 and seeded[2] == "+trap", "a slot naming the wrong category or an unowned item is not trusted",
		show(seeded))

	--==========================================================================
	-- 4. CLEAN
	--==========================================================================
	say("-- clean --")
	local owner = profile({
		Held = { { Id = "x", Tier = 1, Item = "1" }, { Id = "x", Tier = 1, Item = "2" } },
		Weapons = { [BAT1] = true },
		WheelEarned = 3,
	})
	check(show(HotbarSlots.clean(owner, nil)) == "_,_,_,_,_,_,_,_,_,_" and #HotbarSlots.clean(owner, "x") == 10,
		"not a table: ten empty slots")
	local nine = HotbarSlots.clean(owner, { "i:1", "", "", "", "", "", "", "", "i:2" })
	check(#nine == 10 and nine[9] == "i:2" and nine[10] == "", "nine entries come back as ten, in place")
	local eleven = HotbarSlots.clean(owner, { "", "", "", "", "", "", "", "", "", "i:1", "i:2" })
	check(#eleven == 10 and eleven[10] == "i:1" and HotbarSlots.slotOf(eleven, "i:2") == nil,
		"an eleventh entry is never read")
	local mixed = HotbarSlots.clean(owner, { 5, 0 / 0, {}, true, string.rep("w", 33), "i:1", "i:1", "i:7", "x:1", "ticket" })
	check(show(mixed) == "_,_,_,_,_,i:1,_,_,_,ticket",
		"numbers, NaN, tables, booleans, long strings, a second copy, unowned refs and junk prefixes empty their slot", show(mixed))
	check(HotbarSlots.clean(owner, { "w:" .. TRAP1, "w:" .. BAT1 })[1] == "", "an unowned weapon is dropped")
	check(HotbarSlots.clean(profile({ WheelEarned = 0 }), { "ticket" })[1] == "", "the ticket at a balance of 0 is dropped")
	local held = { "+bat", "+bat", "+trap", "", "", "", "", "", "", "+ticket" }
	check(show(HotbarSlots.clean(owner, held)) == "+bat,_,+trap,_,_,_,_,_,_,+ticket",
		"placeholders: allowed by default, and kept once each", show(HotbarSlots.clean(owner, held)))
	local only = HotbarSlots.clean(owner, held, { ["+trap"] = true })
	check(show(only) == "_,_,+trap,_,_,_,_,_,_,_", "with a list, only the placeholders it names survive", show(only))
	local moved = HotbarSlots.clean(owner, { "", "", "", "", "", "", "", "+trap" }, { ["+trap"] = true })
	check(moved[8] == "+trap", "a faint slot may be moved")
	check(HotbarSlots.clean(owner, { "" }, {})[1] == "" and #HotbarSlots.clean(owner, {}, {}) == 10,
		"ten empty strings stay empty")

	--==========================================================================
	-- 5. FILL (load only)
	--==========================================================================
	say("-- fill --")
	local filled = HotbarSlots.fill(profile({ Weapons = { [BAT1] = true }, WheelEarned = 2 }), bar("+bat", "+trap", "+ticket"))
	check(show(filled) == "w:" .. BAT1 .. ",+trap,ticket,_,_,_,_,_,_,_",
		"a faint slot whose category is owned and placed nowhere gets the seed's choice", show(filled))
	local already = HotbarSlots.fill(profile({ Weapons = { [BAT1] = true, [BATN] = true } }), bar("+bat", "", "", "w:" .. BAT1))
	check(already[1] == "+bat", "not when that category is already on the bar", show(already))

	--==========================================================================
	-- 6. FAVOURITES AND PRUNE
	--==========================================================================
	say("-- favourites and prune --")
	local fav = HotbarSlots.cleanFavourites(owner, { ["i:1"] = true, ["i:9"] = true, ["+bat"] = true, ticket = true,
		["w:" .. BAT1] = 1, [5] = true })
	check(fav["i:1"] and fav.ticket and not fav["i:9"] and not fav["+bat"] and not fav["w:" .. BAT1] and not fav[5],
		"favourites: only owned refs saved true, never a placeholder")
	check(next(HotbarSlots.cleanFavourites(owner, "x")) == nil, "not a table: no favourites")
	check(HotbarSlots.isFavourite({ Favourites = { ["i:1"] = true } }, "i:1") and not HotbarSlots.isFavourite({}, "i:1")
		and not HotbarSlots.isFavourite(nil, "i:1") and not HotbarSlots.isFavourite({ Favourites = {} }, nil),
		"isFavourite is nil-safe")
	local pp = profile({
		Held = { { Id = "x", Tier = 1, Item = "1" } },
		Weapons = { [BAT1] = true },
		WheelEarned = 0,
		Hotbar = bar("w:" .. BAT1, "+trap", "ticket", "i:1", "i:2"),
		Favourites = { ["i:1"] = true, ["i:2"] = true, ticket = true },
	})
	check(HotbarSlots.prune(pp) == true, "prune says it changed something")
	check(show(pp.Hotbar) == "w:" .. BAT1 .. ",+trap,+ticket,i:1,_,_,_,_,_,_",
		"in place: a gone item's slot empties, a spent ticket's slot turns faint, placeholders stay", show(pp.Hotbar))
	check(pp.Favourites["i:1"] and not pp.Favourites["i:2"] and not pp.Favourites.ticket, "a gone favourite is forgotten")
	check(HotbarSlots.prune(pp) == false, "pruning again changes nothing")
	local twoFaint = profile({ WheelEarned = 0, Hotbar = bar("+ticket", "ticket") })
	HotbarSlots.prune(twoFaint)
	check(show(twoFaint.Hotbar) == "+ticket,_,_,_,_,_,_,_,_,_", "never a second +ticket", show(twoFaint.Hotbar))
	check(HotbarSlots.prune({}) == false and HotbarSlots.prune(nil) == false, "a profile without the fields is left alone")

	--==========================================================================
	-- 7. THE CLIENT'S EDITS
	--==========================================================================
	say("-- edits --")
	local b = bar("w:a", "+trap", "", "i:1")
	check(HotbarSlots.slotOf(b, "i:1") == 4 and HotbarSlots.slotOf(b, "i:9") == nil and HotbarSlots.slotOf(b, "") == nil,
		"slotOf")
	check(HotbarSlots.firstEmpty(b, 5) == 3 and HotbarSlots.firstEmpty(bar("a", "b", "c", "d", "e"), 5) == nil
		and HotbarSlots.firstEmpty(bar("a", "b", "c", "d", "e"), 10) == 6, "firstEmpty looks only at the shown slots")
	local a1, displaced = HotbarSlots.assign(b, "i:5", 4)
	check(a1[4] == "i:5" and displaced == "i:1" and b[4] == "i:1", "assign onto an item displaces it to the grid; the argument is untouched")
	a1, displaced = HotbarSlots.assign(b, "i:5", 2)
	check(a1[2] == "i:5" and displaced == nil, "assign onto a faint slot drops the placeholder")
	a1, displaced = HotbarSlots.assign(b, "i:1", 1)
	check(a1[1] == "i:1" and a1[4] == "w:a" and displaced == nil, "assign of something already placed swaps the two slots")
	local s = HotbarSlots.swap(b, 1, 3)
	check(s[1] == "" and s[3] == "w:a", "swap moves into an empty slot too")
	check(HotbarSlots.remove(b, 4)[4] == "" and HotbarSlots.remove(b, 11)[4] == "i:1", "remove empties one slot")

	--==========================================================================
	-- 8. ARRIVALS
	--==========================================================================
	say("-- arrivals --")
	local fresh = bar("+bat", "+trap", "+ticket")
	local got, at = HotbarSlots.arrive(fresh, "i:1", 5)
	check(at == 4 and got[4] == "i:1", "a new player's first pod lands in slot 4", show(got))
	got, at = HotbarSlots.arrive(fresh, "w:" .. TRAP1, 5)
	check(at == 2 and got[2] == "w:" .. TRAP1, "a trap takes the faint +trap")
	got, at = HotbarSlots.arrive(bar("i:1", "i:2", "i:3", "i:4", "i:5", "", "", "+bat"), "w:" .. BAT1, 5)
	check(at == 8, "its own faint slot even outside the shown five")
	got, at = HotbarSlots.arrive(bar("i:1", "i:2", "i:3", "i:4", "i:5", "+trap"), "w:" .. BAT1, 5)
	check(at == nil and got[6] == "+trap", "never another category's faint slot; a full bar sends it to the grid")
	got, at = HotbarSlots.arrive(bar("", "i:1"), "i:1", 5)
	check(at == nil and got[1] == "", "already placed: nothing moves")
	got, at = HotbarSlots.arrive(bar("+bat", "+trap", "+ticket"), "ticket", 5)
	check(at == 3, "the next ticket comes back to its faint slot")

	-- A PLANTED creature's slot gives way (option A, the owner's call 2026-10-08):
	-- on a phone two creatures planted from slots 4 and 5 sent every pod stolen
	-- after them to the Bag, past two slots that looked empty.
	local grown = { Held = { { Item = "3" } }, Plants = { { Item = "1" }, { Item = "2" }, { Item = "3" }, { Item = "" }, "junk" } }
	local planted = HotbarSlots.planted(grown)
	check(planted["i:1"] and planted["i:2"] and not planted["i:3"] and planted["i:"] == nil,
		"planted: the creatures in the ground and not in the Bag")
	check(next(HotbarSlots.planted({ Held = {} })) == nil and next(HotbarSlots.planted(nil)) == nil, "planted: nothing in the ground, nothing")
	local phone = bar("w:" .. BAT1, "w:" .. TRAP1, "ticket", "i:1", "i:2")
	got, at = HotbarSlots.arrive(phone, "i:9", 5, planted)
	check(at == 4 and got[4] == "i:9" and got[5] == "i:2", "a stolen pod takes the first shown slot a planted creature keeps", show(got))
	got, at = HotbarSlots.arrive(phone, "i:9", 5)
	check(at == nil and got[4] == "i:1", "without the planted set and without sliding (a Bag tile press): the grid")
	got, at = HotbarSlots.arrive(bar("w:" .. BAT1, "w:" .. TRAP1, "ticket", "i:1", ""), "i:9", 5, planted)
	check(at == 5 and got[4] == "i:1", "a truly empty slot first: a planted shortcut gives way only when it must")
	got, at = HotbarSlots.arrive(bar("w:" .. BAT1, "w:" .. TRAP1, "ticket", "i:3", "i:4", "i:1"), "i:9", 5, planted)
	check(at == nil and got[6] == "i:1", "only a SHOWN slot: a planted shortcut past the phone's five stays")
	got, at = HotbarSlots.arrive(bar("w:" .. BAT1, "w:" .. TRAP1, "ticket", "i:3", "i:4"), "i:9", 5, planted)
	check(at == nil, "without sliding, a creature in the Bag keeps its slot: only the ground gives way")

	-- A PLANT ALWAYS LANDS ON THE BAR (the owner, 2026-10-08): with no room the
	-- shown plant slots slide -- the left-most (oldest) leaves for the Bag, the
	-- newcomer takes the right-most. Hearts are not spared; weapons never move.
	local pushed
	got, at, pushed = HotbarSlots.arrive(phone, "i:9", 5, {}, true)
	check(at == 5 and got[4] == "i:2" and got[5] == "i:9" and pushed == "i:1" and got[1] == "w:" .. BAT1,
		"phone, slots 4-5 full: the oldest leaves, the other slides to 4, the new pod lands on 5", show(got))
	local desk = bar("w:" .. BAT1, "w:" .. TRAP1, "ticket", "i:1", "i:2", "i:3", "i:4", "i:5", "i:6", "i:7")
	got, at, pushed = HotbarSlots.arrive(desk, "i:9", 10, {}, true)
	check(at == 10 and pushed == "i:1" and show(got) == show(bar("w:" .. BAT1, "w:" .. TRAP1, "ticket",
		"i:2", "i:3", "i:4", "i:5", "i:6", "i:7", "i:9")), "desktop, 4-0 full: every plant slides one left", show(got))
	got, at, pushed = HotbarSlots.arrive(bar("w:" .. BAT1, "i:1", "w:" .. TRAP1, "i:2", "ticket"), "i:9", 5, {}, true)
	check(pushed == "i:1" and show(got) == show(bar("w:" .. BAT1, "i:2", "w:" .. TRAP1, "i:9", "ticket")),
		"a weapon between plants stays put: only the plant slots slide", show(got))
	got, at, pushed = HotbarSlots.arrive(bar("+bat", "+trap", "+ticket", "i:1", "i:2"), "i:9", 5, {}, true)
	check(pushed == "i:1" and got[1] == "+bat" and got[3] == "+ticket" and got[4] == "i:2" and got[5] == "i:9",
		"faint slots never slide and are never taken by a plant")
	got, at, pushed = HotbarSlots.arrive(phone, "i:9", 5, planted, true)
	check(at == 4 and pushed == "i:1" and got[5] == "i:2", "a planted creature's slot still goes first: nothing slides")
	got, at, pushed = HotbarSlots.arrive(bar("w:" .. BAT1, "w:" .. TRAP1, "ticket", "i:1", ""), "i:9", 5, {}, true)
	check(at == 5 and pushed == nil, "an empty shown slot first: nothing pushed")
	got, at, pushed = HotbarSlots.arrive(bar("w:" .. BAT1, "w:" .. TRAP1, "ticket", "i:3", "i:4", "i:1"), "i:9", 5, {}, true)
	check(pushed == "i:3" and got[4] == "i:4" and got[5] == "i:9" and got[6] == "i:1", "only the SHOWN plant slots slide")
	got, at = HotbarSlots.arrive(bar("i:1", "i:2", "i:3", "i:4", "i:5", "+trap"), "w:" .. BAT1, 5, {}, true)
	check(at == nil and got[1] == "i:1", "a weapon with no room never pushes a plant off: the grid")
	got, at = HotbarSlots.arrive(bar("w:" .. BAT1, "w:" .. TRAP1, "ticket", "i:7", ""), "i:9", 5, {}, true)
	got, at, pushed = HotbarSlots.arrive(got, "i:7", 5, {}, true)
	check(at == nil and pushed == nil and got[4] == "i:7", "already on the bar (a creature that kept its slot): nothing moves")

	-- Picked up out of the garden: an arrival too.
	local back = HotbarSlots.pickedUp({ ["i:1"] = true, ["i:2"] = true, ["i:5"] = true }, { ["i:2"] = true },
		{ ["i:1"] = true, ["i:2"] = true })
	check(#back == 1 and back[1] == "i:1", "pickedUp: out of the ground and still owned (one sold from the garden is gone)",
		table.concat(back, " "))
	check(#HotbarSlots.pickedUp(nil, {}, { ["i:1"] = true }) == 0, "pickedUp: no last packet, nothing")
	local list = HotbarSlots.arrivals({ ["i:2"] = true }, { ["i:2"] = true, ["i:10"] = true, ["i:9"] = true, ticket = true,
		["w:" .. TRAP1] = true, ["w:" .. BAT1] = true })
	check(table.concat(list, " ") == table.concat({ "w:" .. BAT1, "w:" .. TRAP1, "ticket", "i:9", "i:10" }, " "),
		"arrivals: weapons in shop order, the ticket, then items by number", table.concat(list, " "))

	--==========================================================================
	-- 9. TOOLS AND THE STORAGE COUNT
	--==========================================================================
	say("-- tools and storage --")
	local function tool(attrs)
		return { GetAttribute = function(_, name)
			return attrs[name]
		end }
	end
	check(HotbarSlots.refOfTool(tool({ ItemId = "12" })) == "i:12", "a plant Tool names its item")
	check(HotbarSlots.refOfTool(tool({ WeaponId = BAT1 })) == "w:" .. BAT1, "a bat Tool names its weapon")
	check(HotbarSlots.refOfTool(tool({ SpinTicket = true })) == "ticket", "the ticket Tool is the stack")
	check(HotbarSlots.refOfTool(tool({ SpeciesId = "nubkin" })) == nil and HotbarSlots.refOfTool(tool({ ItemId = "" })) == nil
		and HotbarSlots.refOfTool(tool({ WeaponId = "no_such_bat" })) == nil and HotbarSlots.refOfTool(nil) == nil,
		"a Tool that has not learned its id names nothing yet")
	local t1, full1, known1 = HotbarSlots.storage(4, false, 24)
	local t2, full2 = HotbarSlots.storage(23, true, 24)
	local t3, _, known3 = HotbarSlots.storage(nil, false, 24)
	check(t1 == "4/24" and not full1 and known1, "4/24", t1)
	check(t2 == "23+1/24" and full2, "a carried pod is said, and counts toward full", t2)
	check(t3 == "…" and not known3, "before the profile: no number")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nHotbarSlotsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
