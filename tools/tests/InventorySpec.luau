--!nocheck
--==============================================================================
-- Steal a Seed :: InventorySpec
--
-- The freely assignable hotbar and the Bag's hearts, on the server (2026-10-03,
-- the owner's compact Bag + free hotbar). Edit mode, with the REAL
-- ProfileSchema, PlayerDataService, InventoryService and CarryService,
-- fresh-required, and stand-in players joined the way AdminSpec joins them:
-- SaveService's Load and Save are stubbed, so no DataStore is read or written
-- and no real profile is touched.
--
--   1. migration: a save without a bar is seeded from what it has out, junk is
--      cleaned rather than re-seeded, a JSON round trip keeps ids, bar, hearts
--   2. HotbarSet: cleaned against what is owned NOW, faint slots only moved
--   3. Favourite: owned refs only, never a faint slot, at most 32 a request
--   4. the token bucket: charged first, refilled, per player
--   5. prune: through SetHeld, a real SyncHeldNow (by name, and B2's orphan
--      preference for a Tool that never learned its id), and UpdateWheel
--   6. a HotbarSet racing a sale; the progress reset (NextItem kept)
--
-- Not here: the client's edits (HotbarSlotsSpec, HotbarSpec) and a real
-- respawn (HeldRestoreSpec, Play).
--==============================================================================
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local HotbarSlots = require(Shared.HotbarSlots)
local WeaponData = require(Shared.WeaponData)
local SeedData = require(Shared.SeedData)
local Server = game:GetService("ServerScriptService").SeedGameServer
local SaveService = require(Server.SaveService)
local PlotService = require(Server.PlotService)
local ProfileSchema = require(Server.ProfileSchema)
local PlayerDataService = require(Server.PlayerDataService)
local InventoryService = require(Server.InventoryService)
local CarryService = require(Server.CarryService)

local INV = GameConfig.Inventory

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
local function sourceOf(instance)
	local ok, src = pcall(function()
		return instance and instance.Source
	end)
	return if ok and src then src else ""
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

local bats, traps = {}, {}
for _, item in ipairs(WeaponData.Items) do
	table.insert(if item.Category == "bat" then bats else traps, item.Id)
end
local BAT1, BATN, TRAP1 = bats[1], bats[#bats], traps[1]
local SPECIES = SeedData.Species[1]

local fixture = Instance.new("Folder")
fixture.Name = "InventorySpecFixture"
fixture.Archivable = false
fixture.Parent = ServerStorage

--==============================================================================
-- THE STUBS
--==============================================================================
local saves: any, plots: any, data: any, inventory: any = SaveService, PlotService, PlayerDataService,
	InventoryService
local real = {
	Load = saves.Load, Save = saves.Save, Forget = saves.Forget,
	SetDesiredLevel = plots.SetDesiredLevel, PlotOf = plots.PlotOf,
	MountStats = data.MountStats, Clock = inventory.Clock,
}
local answer = { status = "ok", raw = nil }
saves.Load = function()
	return answer.status, answer.raw
end
saves.Save = function()
	return true
end
saves.Forget = function() end
plots.PlotOf = function()
	return nil
end
plots.SetDesiredLevel = function()
	return true
end
local holders = {}
data.MountStats = function(holder, profile)
	return real.MountStats(holders[holder] or holder, profile)
end
local clock = 1000
inventory.Clock = function()
	return clock
end

local function stand(name, userId)
	local holder = Instance.new("Folder")
	holder.Name = name
	holder.Parent = fixture
	local characterAdded = Instance.new("BindableEvent")
	characterAdded.Parent = holder
	local backpack = Instance.new("Backpack")
	backpack.Parent = holder
	local character = Instance.new("Model")
	character.Name = name .. "Body"
	character.Parent = holder
	local attrs = {}
	local p = {
		Name = name,
		UserId = userId,
		Parent = Players,
		Character = character,
		CharacterAdded = characterAdded.Event,
		_backpack = backpack,
	}
	function p.SetAttribute(_, k, v)
		attrs[k] = v
	end
	function p.GetAttribute(_, k)
		return attrs[k]
	end
	function p.Kick() end
	function p.FindFirstChildOfClass(_, className)
		if className == "Backpack" and backpack.Parent then
			return backpack
		end
		return nil
	end
	function p.WaitForChild(_, childName)
		return holder:FindFirstChild(childName)
	end
	holders[p] = holder
	return p
end

local joined = {}
local function join(name, userId, shape)
	local raw = ProfileSchema.Sanitise(nil)
	for k, v in pairs(shape or {}) do
		raw[k] = v
	end
	answer.status, answer.raw = "ok", raw
	local p = stand(name, userId)
	data.Join(p)
	table.insert(joined, p)
	return p, data.Get(p)
end

local function plantTool(parent, item, tier)
	local t = Instance.new("Tool")
	t.Name = SPECIES.Name
	t.RequiresHandle = false
	t:SetAttribute("SpeciesId", SPECIES.Id)
	t:SetAttribute(GameConfig.Attributes.CarryingKg, tier or 1)
	t:SetAttribute("Hatched", true)
	if item then
		t:SetAttribute(GameConfig.Attributes.ItemId, item)
	end
	t.Parent = parent
	return t
end

local function row(item, tier)
	return { Id = SPECIES.Id, Tier = tier or 1, Hatched = true, Item = item }
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. MIGRATION
	--==========================================================================
	say("-- migration --")
	local d = ProfileSchema.Default()
	check(show(d.Hotbar) == show(HotbarSlots.seed(nil)) and next(d.Favourites) == nil,
		"a new profile: the three faint slots and no hearts", show(d.Hotbar))
	check(show(ProfileSchema.Sanitise(nil).Hotbar) == "+bat,+trap,+ticket,_,_,_,_,_,_,_", "Sanitise(nil) is the same")
	local old = ProfileSchema.Sanitise({
		Weapons = { [BAT1] = true, [TRAP1] = true }, EquippedBat = BAT1, EquippedTrap = TRAP1, WheelEarned = 2,
		Held = { { Id = SPECIES.Id, Tier = 1, Hatched = true }, { Id = SPECIES.Id, Tier = 1, Hatched = true } },
	})
	check(old.Hotbar[1] == "w:" .. BAT1 and old.Hotbar[2] == "w:" .. TRAP1 and old.Hotbar[3] == "ticket"
		and old.Hotbar[4] == "", "an existing save with no bar: 1 its bat, 2 its trap, 3 its tickets", show(old.Hotbar))
	check(old.Held[1].Item == "1" and old.Held[2].Item == "2" and old.NextItem == 3,
		"and its rows are given ids 1..n in order, NextItem past them")
	local legacy = ProfileSchema.Sanitise({ Weapons = { [BATN] = true }, Equipped = BATN })
	check(legacy.Hotbar[1] == "w:" .. BATN and legacy.Hotbar[2] == "+trap" and legacy.Hotbar[3] == "+ticket",
		"the one-slot save's Equipped is sorted in first, then seeded", show(legacy.Hotbar))
	local unequipped = ProfileSchema.Sanitise({ Weapons = { [BAT1] = true, [BATN] = true } })
	check(unequipped.Hotbar[1] == "w:" .. BATN, "owning bats with none out: the last owned in shop order")
	local junk = ProfileSchema.Sanitise({ Hotbar = { "i:99", 5, "w:" .. BAT1, "nope" }, Weapons = {} })
	check(show(junk.Hotbar) == "_,_,_,_,_,_,_,_,_,_", "a junk bar is cleaned, not re-seeded", show(junk.Hotbar))
	local emptied = ProfileSchema.Sanitise({ Hotbar = HotbarSlots.empty(), Weapons = { [BAT1] = true }, WheelEarned = 3 })
	check(show(emptied.Hotbar) == "_,_,_,_,_,_,_,_,_,_", "a bar the player emptied stays empty")
	local filled = ProfileSchema.Sanitise({ Hotbar = bar("+bat", "+trap", "+ticket"), Weapons = { [BAT1] = true },
		EquippedBat = BAT1, WheelEarned = 4 })
	check(show(filled.Hotbar) == "w:" .. BAT1 .. ",+trap,ticket,_,_,_,_,_,_,_",
		"a faint slot whose kind is owned and placed nowhere is filled at load", show(filled.Hotbar))
	local favs = ProfileSchema.Sanitise({ Held = { row("7") }, Favourites = { ["i:7"] = true, ["i:8"] = true,
		["+bat"] = true } })
	check(favs.Favourites["i:7"] and not favs.Favourites["i:8"] and not favs.Favourites["+bat"],
		"hearts are cleaned against what is owned")
	-- The JSON round trip a DataStore makes.
	local rich = ProfileSchema.Sanitise({
		Held = { row("4"), row("9"), row(nil) },
		NextItem = 12,
		Weapons = { [BAT1] = true },
		WheelEarned = 1,
		Hotbar = bar("w:" .. BAT1, "+trap", "ticket", "i:9", "", "", "", "", "", "i:4"),
		Favourites = { ["i:4"] = true, ticket = true },
	})
	local back = ProfileSchema.Sanitise(HttpService:JSONDecode(HttpService:JSONEncode(rich)))
	check(back.Held[1].Item == "4" and back.Held[2].Item == "9" and back.Held[3].Item == "12" and back.NextItem == 13,
		"ids survive the round trip; a row without one is given the next number")
	check(show(back.Hotbar) == show(rich.Hotbar) and back.Favourites["i:4"] and back.Favourites.ticket,
		"the bar and the hearts survive it", show(back.Hotbar))
	local none = ProfileSchema.Sanitise(HttpService:JSONDecode(HttpService:JSONEncode(ProfileSchema.Default())))
	check(type(none.Favourites) == "table" and next(none.Favourites) == nil and #none.Hotbar == 10,
		"an empty heart set survives as a set ([] decodes to {})")

	--==========================================================================
	-- 2. HotbarSet
	--==========================================================================
	say("-- HotbarSet --")
	local p, prof = join("InvA", 900001, {
		Held = { row("1"), row("2"), row("3") }, NextItem = 4,
		Weapons = { [BAT1] = true }, EquippedBat = BAT1, WheelEarned = 3,
		Hotbar = bar("w:" .. BAT1, "+trap", "ticket"),
	})
	check(prof ~= nil and show(prof.Hotbar) == "w:" .. BAT1 .. ",+trap,ticket,_,_,_,_,_,_,_", "joined with a bar",
		prof and show(prof.Hotbar))
	local want = bar("w:" .. BAT1, "+trap", "ticket", "i:2", "i:1")
	check(inventory.Handle(p, INV.SetAction, want) == true and show(prof.Hotbar) == show(want),
		"a bar of owned refs is saved as sent", show(prof.Hotbar))
	clock += 10
	check(inventory.Handle(p, INV.SetAction, want) == false, "the same bar again changes nothing")
	clock += 10
	inventory.Handle(p, INV.SetAction, bar("+bat", "i:1", "", "i:99", "+trap", "i:1", "w:" .. TRAP1))
	check(show(prof.Hotbar) == "_,i:1,_,_,+trap,_,_,_,_,_",
		"a faint slot the bar did not have is refused, one it had may move; unowned and doubled refs go",
		show(prof.Hotbar))
	clock += 10
	check(inventory.Handle(p, INV.SetAction, "x") == false and inventory.Handle(p, INV.SetAction, nil) == false,
		"not a table: refused")
	check(inventory.Handle(p, "SomethingElse", want) == false, "another verb is not this one's")
	local gone = stand("InvGone", 900009)
	check(inventory.Handle(gone, INV.SetAction, want) == false, "a player with no profile: refused")

	--==========================================================================
	-- 3. Favourite
	--==========================================================================
	say("-- Favourite --")
	clock += 10
	check(inventory.Handle(p, INV.FavouriteAction, { "i:1", "i:2" }, true) == true
		and prof.Favourites["i:1"] and prof.Favourites["i:2"], "a group's copies are favourited together")
	check(inventory.Handle(p, INV.FavouriteAction, { "i:1" }, true) == false, "already favourited: no change")
	check(data.SetFavourite(p, { "i:1", "+bat", "i:99", "w:" .. TRAP1, 7 }, false) == 1
		and not prof.Favourites["i:1"] and prof.Favourites["i:2"], "off, for owned refs only")
	check(data.SetFavourite(p, { "+bat" }, true) == 0 and data.SetFavourite(p, { "i:3" }, "yes") == 0
		and data.SetFavourite(p, "i:3", true) == 0, "a faint slot, a non-boolean and a non-table change nothing")
	local many = {}
	for i = 1, INV.MaxPerRequest do
		many[i] = "i:2"
	end
	many[INV.MaxPerRequest + 1] = "i:3"
	data.SetFavourite(p, many, true)
	check(not prof.Favourites["i:3"], "no more than MaxPerRequest refs are read from one request")
	check(data.SetFavourite(p, { "w:" .. BAT1, "ticket" }, true) == 2, "a bat and the ticket stack can wear a heart")

	--==========================================================================
	-- 4. THE TOKEN BUCKET
	--==========================================================================
	say("-- the token bucket --")
	clock += 100
	-- Always a real change, so only the bucket can refuse it.
	local function toggle(who)
		local now = data.Get(who).Favourites["i:3"] == true
		return inventory.Handle(who, INV.FavouriteAction, { "i:3" }, not now)
	end
	local passed = 0
	for _ = 1, INV.Burst do
		if toggle(p) then
			passed += 1
		end
	end
	check(passed == INV.Burst, "a burst of 12 passes", passed)
	check(toggle(p) == false, "the 13th in the same moment is refused, valid as it is")
	clock += 1 / INV.RefillPerSecond
	check(toggle(p) == true and toggle(p) == false, "one more after 1/8 s, and only one")
	clock += 1000
	passed = 0
	for _ = 1, INV.Burst + 3 do
		if toggle(p) then
			passed += 1
		end
	end
	check(passed == INV.Burst, "a long rest refills to 12 and no further", passed)
	clock += 1000
	for _ = 1, INV.Burst do
		inventory.Handle(p, INV.SetAction, "junk")
	end
	check(toggle(p) == false, "malformed requests pay their token too")
	local q, qprof = join("InvB", 900002, { Held = { row("1") }, NextItem = 2 })
	check(inventory.Handle(q, INV.FavouriteAction, { "i:1" }, true) == true and qprof.Favourites["i:1"],
		"another player has a bucket of their own")
	inventory.Forget(p)
	check(toggle(p) == true, "forgotten on leaving: a fresh bucket")
	local src = sourceOf(Server:FindFirstChild("InventoryService"))
	local handle = string.match(src, "function InventoryService%.Handle(.-)\nend\n") or ""
	local chargeAt = string.find(handle, "charge(player)", 1, true)
	local setAt = string.find(handle, "PlayerDataService.SetHotbar", 1, true)
	check(chargeAt ~= nil and setAt ~= nil and chargeAt < setAt, "the token is charged before the payload is read")
	check(string.find(src, "Players.PlayerRemoving:Connect", 1, true) ~= nil
		and string.find(src, "GameConfig.Remotes.GameEvent", 1, true) ~= nil,
		"the verbs ride the GameEvent remote, and a leaving player's bucket goes")

	--==========================================================================
	-- 5. PRUNE
	--==========================================================================
	say("-- prune --")
	clock += 100
	data.SetHotbar(p, bar("w:" .. BAT1, "+trap", "ticket", "i:2", "i:1", "i:3"))
	data.SetFavourite(p, { "i:1", "i:2", "i:3" }, true)
	local kept = {}
	for _, r in ipairs(prof.Held) do
		if r.Item ~= "1" then
			table.insert(kept, r)
		end
	end
	data.SetHeld(p, kept)
	check(HotbarSlots.slotOf(prof.Hotbar, "i:1") == nil and prof.Hotbar[5] == "" and not prof.Favourites["i:1"],
		"SetHeld without a row: its shortcut empties and its heart goes", show(prof.Hotbar))
	check(prof.Hotbar[4] == "i:2" and prof.Favourites["i:2"], "everything else stays where it was")
	-- A real SyncHeldNow with the Tool a sale consumed, on an unarmed stand-in.
	local sold = plantTool(nil, "2")
	CarryService.SyncHeldNow(p, { sold })
	check(prof.Hotbar[4] == "" and not prof.Favourites["i:2"] and prof.Hotbar[6] == "i:3",
		"a real SyncHeldNow takes exactly that item's row, shortcut and heart", show(prof.Hotbar))
	-- B2: a consumed Tool that never learned its id takes an ORPHAN of its kind.
	local r, rprof = join("InvC", 900003, { Held = { row("1"), row("2") }, NextItem = 3,
		Hotbar = bar("i:1", "i:2") })
	plantTool(r._backpack, "1")
	CarryService.SyncHeldNow(r, { plantTool(nil, nil) })
	check(#rprof.Held == 1 and rprof.Held[1].Item == "1" and rprof.Hotbar[1] == "i:1" and rprof.Hotbar[2] == "",
		"a Tool with no id takes the row no live Tool names (its twin keeps its own)", show(rprof.Hotbar))
	-- Tickets through UpdateWheel.
	data.SetHotbar(p, bar("w:" .. BAT1, "+trap", "ticket"))
	data.SetFavourite(p, { "ticket" }, true)
	local before = show(prof.Hotbar)
	data.UpdateWheel(p, function()
		return false
	end)
	check(show(prof.Hotbar) == before and prof.Favourites.ticket, "an UpdateWheel that changes nothing prunes nothing")
	data.UpdateWheel(p, function(profile)
		profile.WheelEarned = 0
		return true
	end)
	check(prof.Hotbar[3] == "+ticket" and not prof.Favourites.ticket,
		"tickets spent to 0: the slot turns faint and the heart goes", show(prof.Hotbar))

	--==========================================================================
	-- 6. A SALE RACE, AND THE RESET
	--==========================================================================
	say("-- a sale race, and the reset --")
	clock += 100
	local s, sprof = join("InvD", 900004, { Held = { row("5"), row("6") }, NextItem = 7, Weapons = { [BAT1] = true } })
	local stale = bar("w:" .. BAT1, "", "", "i:5", "i:6")
	data.SetHeld(s, { row("6") })
	inventory.Handle(s, INV.SetAction, stale)
	check(sprof.Hotbar[4] == "" and sprof.Hotbar[5] == "i:6", "an edit that raced a sale cannot bring the sold item back",
		show(sprof.Hotbar))
	data.SetFavourite(s, { "i:6" }, true)
	check(data.ResetProgress(s) == true, "the reset runs")
	sprof = data.Get(s)
	check(show(sprof.Hotbar) == show(HotbarSlots.seed(nil)) and next(sprof.Favourites) == nil,
		"after a reset: the three faint slots and no hearts", show(sprof.Hotbar))
	check(sprof.NextItem == 7, "NextItem is kept, so no id is ever handed out twice", sprof.NextItem)
	clock += 100
	inventory.Handle(s, INV.SetAction, stale)
	check(HotbarSlots.slotOf(sprof.Hotbar, "i:6") == nil and HotbarSlots.slotOf(sprof.Hotbar, "w:" .. BAT1) == nil,
		"a stale bar after the reset cannot restore the old refs", show(sprof.Hotbar))
	local pds = sourceOf(Server:FindFirstChild("PlayerDataService"))
	local setHeld = string.match(pds, "function PlayerDataService%.SetHeld(.-)\nend\n") or ""
	check(string.find(setHeld, "HotbarSlots.prune(entry.profile)", 1, true) ~= nil
		and string.find(setHeld, "warn(", 1, true) ~= nil,
		"SetHeld prunes, and says so when it has to re-mint an id")
end)

for _, p in ipairs(joined) do
	p.Parent = Players
	pcall(data.Leave, p)
end
saves.Load, saves.Save, saves.Forget = real.Load, real.Save, real.Forget
plots.SetDesiredLevel, plots.PlotOf = real.SetDesiredLevel, real.PlotOf
data.MountStats = real.MountStats
inventory.Clock = real.Clock
fixture:Destroy()

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nInventorySpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
