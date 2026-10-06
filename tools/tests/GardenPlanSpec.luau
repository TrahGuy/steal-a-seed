--!nocheck
--==============================================================================
-- Steal a Seed :: GardenPlanSpec
--
-- MY PLANTS (2026-10-04): what EQUIP BEST decides, by arithmetic, and the
-- wiring that keeps a creature itself while it moves between the Bag and the
-- ground.
--
--   1. ranking: the faucet's own per-plant number (SeedData.IncomePerSecond),
--      highest first; equal incomes keep what is planted, then the lower item
--      id; the pods' slots are never given away
--   2. stability: a lineup EQUIP BEST has just made is left alone by the next
--      press, and a shuffled candidate list changes nothing
--   3. room: a change is checked whole against the Bag (a raid pod's kept place
--      counted) -- a swap with a full Bag fits, an UNEQUIP ALL that cannot fit
--      is refused
--   4. spots: inside the beds, spread out, the same for the same garden
--   5. wiring: the item id rides into the ground and back, shortcuts and
--      hearts count a planted item as owned, a saved planted id never
--      duplicates a Bag id, and the server's verbs check before they move
--
-- Not here, seen in Play instead: the panel, a real swap, a rejoin.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local GardenPlan = require(Shared.GardenPlan)
local HotbarSlots = require(Shared.HotbarSlots)
local SeedData = require(Shared.SeedData)
local GameConfig = require(Shared.GameConfig)

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
local function keys(list)
	local t = {}
	for _, c in ipairs(list) do
		table.insert(t, c.key)
	end
	return table.concat(t, ",")
end
local function planted(id, income, item)
	return { key = "p:" .. id, income = income, planted = true, item = item, placementId = id }
end
local function stored(item, income)
	return { key = "i:" .. item, income = income, planted = false, item = item }
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. RANKING
	--==========================================================================
	say("-- ranking --")
	-- A plot of 5 with one growing pod: 4 slots for creatures.
	local cands = {
		planted(1, 10, "1"), planted(2, 50, "2"), planted(3, 30, "3"), planted(4, 5, "4"),
		stored("7", 40), stored("8", 100), stored("9", 1),
	}
	local plan = GardenPlan.best(cands, 5, 1)
	check(plan.slots == 4 and keys(plan.keep) == "p:2,p:3" and keys(plan.plant) == "i:8,i:7"
			and keys(plan.ret) == "p:1,p:4",
		"the four best earners stand (pods keep their slot); weaker planted ones come out",
		keys(plan.keep) .. " | " .. keys(plan.plant) .. " | " .. keys(plan.ret))
	local ties = GardenPlan.best({ stored("5", 20), planted(9, 20, "12"), stored("3", 20) }, 2, 0)
	check(keys(ties.keep) == "p:9" and keys(ties.plant) == "i:3" and #ties.ret == 0,
		"equal incomes: the planted one first, then the lower item id", keys(ties.keep) .. " | " .. keys(ties.plant))
	local legacy = GardenPlan.best({ planted(4, 20, nil), planted(2, 20, nil), planted(3, 20, "9") }, 2, 0)
	check(keys(legacy.keep) == "p:3,p:2" and keys(legacy.ret) == "p:4",
		"a planted creature with no id ranks after one with an id, then by placement id", keys(legacy.keep))
	local full = GardenPlan.best({ planted(1, 5, "1"), stored("2", 9) }, 3, 3)
	check(full.slots == 0 and #full.plant == 0 and keys(full.ret) == "p:1",
		"a plot full of growing pods takes no creature (and EQUIP BEST never touches a pod)")
	-- The faucet's own number: a Secret's fixed income ranks as itself.
	local secret = SeedData.Get("snarlbloom")
	local nubkin = SeedData.Get("nubkin")
	check(secret ~= nil and SeedData.IncomePerSecond(secret, 1) == secret.FixedIncome
			and SeedData.IncomePerSecond(secret, 7) == SeedData.IncomePerSecond(secret, 1)
			and SeedData.IncomePerSecond(nubkin, 7) > SeedData.IncomePerSecond(nubkin, 1),
		"ranked by SeedData.IncomePerSecond: a Secret's fixed rate, an ordinary plant's size")

	--==========================================================================
	-- 2. STABILITY
	--==========================================================================
	say("\n-- stability --")
	-- Apply a plan, then plan again from the result: nothing moves.
	local after = {}
	for _, c in ipairs(plan.keep) do
		table.insert(after, c)
	end
	for _, c in ipairs(plan.plant) do
		table.insert(after, planted(100 + #after, c.income, c.item))
	end
	for _, c in ipairs(plan.ret) do
		table.insert(after, stored(c.item, c.income))
	end
	table.insert(after, stored("9", 1))
	local again = GardenPlan.best(after, 5, 1)
	check(not GardenPlan.changes(again), "pressing EQUIP BEST again on the lineup it made moves nothing")
	local equal = { planted(1, 20, "1"), planted(2, 20, "2"), stored("3", 20), stored("4", 20) }
	local shuffledSame = true
	for _ = 1, 20 do
		local shuffled = table.clone(equal)
		for i = #shuffled, 2, -1 do
			local j = math.random(1, i)
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		end
		local p = GardenPlan.best(shuffled, 2, 0)
		shuffledSame = shuffledSame and not GardenPlan.changes(p) and keys(p.keep) == "p:1,p:2"
	end
	check(shuffledSame, "equal incomes in any order: the planted pair stays, nothing swaps")

	--==========================================================================
	-- 3. ROOM
	--==========================================================================
	say("\n-- room --")
	local max = GameConfig.Save.MaxHeld
	check(GardenPlan.fits(max, false, 2, 2, max) and not GardenPlan.fits(max, false, 1, 2, max),
		"a swap with a full Bag fits (two in, two out); one more out than in does not")
	check(not GardenPlan.fits(max - 2, true, 2, 4, max) and GardenPlan.fits(max - 3, true, 2, 4, max),
		"a raid pod in the arms keeps its place in the count")
	check(not GardenPlan.fits(max - 3, false, 0, 4, max) and GardenPlan.fits(max - 4, false, 0, 4, max),
		"UNEQUIP ALL fits only when every grown plant fits")

	--==========================================================================
	-- 4. SPOTS
	--==========================================================================
	say("\n-- spots --")
	local beds = { { cx = 0, cz = 0, hx = 10, hz = 6 }, { cx = 30, cz = 0, hx = 4, hz = 4 } }
	local taken = { Vector2.new(0, 0) }
	local a = GardenPlan.spots(beds, taken, 6, 2.5)
	local b = GardenPlan.spots(beds, taken, 6, 2.5)
	local inside, same, minD = true, #a == 6 and #b == 6, math.huge
	for i, p in ipairs(a) do
		same = same and b[i] == p
		local inBed = false
		for _, bed in ipairs(beds) do
			if math.abs(p.X - bed.cx) <= bed.hx + 1e-6 and math.abs(p.Y - bed.cz) <= bed.hz + 1e-6 then
				inBed = true
			end
		end
		inside = inside and inBed
		for j, q in ipairs(a) do
			if j ~= i then
				minD = math.min(minD, (p - q).Magnitude)
			end
		end
		minD = math.min(minD, (p - taken[1]).Magnitude)
	end
	check(inside and same and minD >= 4,
		"newcomers stand inside the beds, spread out (no two closer than 4 studs here), the same every time", minD)

	--==========================================================================
	-- 5. WIRING
	--==========================================================================
	say("\n-- wiring --")
	local profile = { Held = { { Id = "nubkin", Tier = 1, Hatched = true, Item = "3" } },
		Plants = { { SpeciesId = "petalpip", Stage = 3, Item = "5" } }, Weapons = {}, WheelEarned = 0,
		Hotbar = { "i:5", "i:3", "i:9", "", "", "", "", "", "", "" }, Favourites = { ["i:5"] = true, ["i:9"] = true } }
	HotbarSlots.prune(profile)
	check(profile.Hotbar[1] == "i:5" and profile.Hotbar[2] == "i:3" and profile.Hotbar[3] == ""
			and profile.Favourites["i:5"] == true and profile.Favourites["i:9"] == nil
			and HotbarSlots.owns(profile, "i:5"),
		"a planted creature's shortcut and heart are kept (owned); a gone item's are not")
	local plant = sourceOf(ServerScriptService, "PlantService")
	local schema = sourceOf(ServerScriptService, "ProfileSchema")
	check(has(plant, "Item = if entry.stage == CreatureModel.STAGE_GROWN then entry.item else nil,")
			and has(plant, "if bagOnly then -1 else nil, nil, true, entry.item)")
			and has(plant, "item = if hatched and type(tool:GetAttribute(GameConfig.Attributes.ItemId)) == \"string\""),
		"the item id goes into the ground with a creature, is saved with it, and comes back on it")
	check(has(schema, "if used[item] then\n\t\t\t\t\trow.Item = nil") and has(schema, "Item = item,\n\t\t\t\t\t})"),
		"a saved planted id that a Bag row also has is dropped, never duplicated")
	check(has(plant, "if not GardenPlan.fits(heldRows, CarryService.IsCarrying(player), #plan.plant, #plan.ret,")
			and has(plant, "return false, \"STORAGE_FULL_ALL\", 0")
			and has(plant, "if not CarryService.IsHeldRestored(player) then")
			and has(plant, "tool:GetAttribute(HatchRoll.Attribute) == nil"),
		"the verbs check the Bag after the whole change, an armed record and a finished reveal before moving")
	local newcomers = string.find(plant, "-- 1. Newcomers into the ground", 1, true)
	local displaced = string.find(plant, "-- 2. The displaced out, weakest first", 1, true)
	check(newcomers ~= nil and displaced ~= nil and newcomers < displaced,
		"newcomers go in BEFORE the displaced come out, so a swap never needs a free Bag slot")
	check(has(plant, "if now - (lastMyPlants[player] or -math.huge) < MY.Cooldown then"),
		"one request per player per cooldown: repeated presses are answered once")
	local garden = sourceOf(StarterPlayer, "GardenUI")
	check(has(garden, "ask(MY.Plant, sel.itemId)") and has(garden, "ask(MY.Return, sel.id)")
			and has(garden, "ask(MY.Best, nil)") and has(garden, "ask(MY.Clear, nil)")
			and not has(garden, "PickUpAction"),
		"the panel only asks: PLANT by item id, RETURN by placement id, EQUIP BEST, UNEQUIP ALL")
end)

if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nGardenPlanSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
