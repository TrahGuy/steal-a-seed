--!strict
--==============================================================================
-- Steal a Seed :: UsabilityAudioSpec
--
-- The 2026-09-26 usability and audio pass, held to what it promised. Edit mode,
-- through the ZZSpecRun loader like every other spec.
--
--   1. SORT          the Garden's and the Bag's orders: pods never ranked by
--                    what is inside them, ties by a stable id, default untouched
--   2. BASE INCOME   the Bag thumbnail's number is the faucet's per-plant rate
--   3. MENU SIZE     options, the profile field, and the Bag panel's fit
--   4. CHASE BED     pursuit, not carrying; one caller; fades; a resume keeps
--                    its place
--   5. PLOT NUMBERS  published from the pay tick, cleared on release
--   6. WIRING        each menu actually uses the above, and no HUD owner does
--
-- What only Play can show -- the fade reaching silence, the badge on a real
-- plot, a controller's focus after a re-sort -- is verified there and recorded
-- in the handoff; this pins the logic and the wiring.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local PlantInfo = require(Shared.PlantInfo)
local HudLayout = require(Shared.HudLayout)
local SoundKit = require(Shared.SoundKit)
local Server = ServerScriptService.SeedGameServer
local ProfileSchema = require(Server.ProfileSchema)

local pass = 0
local fails: { string } = {}
local notes: { string } = {}
local function check(ok: boolean, label: string, detail: any?)
	if ok then
		pass += 1
	else
		table.insert(fails, label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local function sourceOf(instance: Instance?): string
	if not instance then
		return ""
	end
	local ok, src = pcall(function()
		return (instance :: any).Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local function client(name: string): string
	return sourceOf(scripts and scripts:FindFirstChild(name))
end
local function has(src: string, needle: string): boolean
	return string.find(src, needle, 1, true) ~= nil
end
local function count(src: string, needle: string): number
	local n, at = 0, 1
	while true do
		local i = string.find(src, needle, at, true)
		if not i then
			return n
		end
		n += 1
		at = i + #needle
	end
end

--==============================================================================
-- 1. SORT
--==============================================================================
type Entry = { speciesId: string, tier: number, hatched: boolean, id: number, tag: string }

local function entries(): { Entry }
	-- Duplicates, a big one, two pods, and ids deliberately out of list order.
	return {
		{ speciesId = "nubkin", tier = 1, hatched = true, id = 14, tag = "nubA" },
		{ speciesId = "toadcap", tier = 2, hatched = false, id = 11, tag = "podToad" },
		{ speciesId = "toadcap", tier = 5, hatched = true, id = 12, tag = "toad5" },
		{ speciesId = "nubkin", tier = 1, hatched = true, id = 10, tag = "nubB" },
		{ speciesId = "petalpip", tier = 3, hatched = true, id = 16, tag = "pip3" },
		{ speciesId = "nubkin", tier = 4, hatched = false, id = 13, tag = "podNub" },
	}
end
local function keyOf(e: Entry): PlantInfo.SortKey
	return { speciesId = e.speciesId, tier = e.tier, hatched = e.hatched, id = e.id }
end
local function tags(list: { Entry }): string
	local out = {}
	for _, e in ipairs(list) do
		table.insert(out, e.tag)
	end
	return table.concat(out, ",")
end
local function income(e: Entry): number
	return SeedData.IncomePerSecond(SeedData.Get(e.speciesId) :: any, e.tier)
end

do
	local list = entries()
	local before = tags(list)
	PlantInfo.Sort(list, "default", keyOf)
	check(tags(list) == before, "default leaves the caller's order exactly as it was", tags(list))

	for _, mode in ipairs({ "incomeHigh", "incomeLow", "rarity", "name" }) do
		local sorted = PlantInfo.Sort(entries(), mode, keyOf)
		-- Grown first, pods last, and the pods in id order whatever they hold.
		local seenPod, grownAfterPod = false, false
		local pods = {}
		for _, e in ipairs(sorted) do
			if e.hatched then
				grownAfterPod = grownAfterPod or seenPod
			else
				seenPod = true
				table.insert(pods, e.id)
			end
		end
		check(not grownAfterPod, mode .. ": every pod follows every grown plant", tags(sorted))
		check(#pods == 2 and pods[1] < pods[2], mode .. ": pods keep id order -- never ranked by species or size",
			tags(sorted))
		-- Ties fall to the id, so the two identical Nubkins are id 10 then 14.
		local b, a = 0, 0
		for i, e in ipairs(sorted) do
			if e.tag == "nubB" then b = i end
			if e.tag == "nubA" then a = i end
		end
		check(b > 0 and a > 0 and b < a, mode .. ": identical plants tie-break by their stable id", tags(sorted))
		-- Deterministic: the same set in any order sorts the same.
		local shuffled = entries()
		table.sort(shuffled, function(x: Entry, y: Entry): boolean
			return x.id > y.id
		end)
		PlantInfo.Sort(shuffled, mode, keyOf)
		check(tags(shuffled) == tags(sorted), mode .. ": the input order makes no difference", tags(shuffled))
	end

	local high = PlantInfo.Sort(entries(), "incomeHigh", keyOf)
	local ok = true
	for i = 2, 4 do
		ok = ok and income(high[i - 1]) >= income(high[i])
	end
	check(ok and high[1].tag == "toad5", "income high: highest first, the tier-5 Toadcap on top", tags(high))
	local low = PlantInfo.Sort(entries(), "incomeLow", keyOf)
	check(low[1].tag == "nubB" and low[2].tag == "nubA" and low[4].tag == "toad5",
		"income low: lowest first", tags(low))
	local rare = PlantInfo.Sort(entries(), "rarity", keyOf)
	local rOk = true
	for i = 2, 4 do
		local ra = GameConfig.RarityTier[(SeedData.Get(rare[i - 1].speciesId) :: any).Rarity] or 0
		local rb = GameConfig.RarityTier[(SeedData.Get(rare[i].speciesId) :: any).Rarity] or 0
		rOk = rOk and ra >= rb
	end
	check(rOk, "rarity: rarest first by GameConfig.RarityTier", tags(rare))
	local named = PlantInfo.Sort(entries(), "name", keyOf)
	local nOk = true
	for i = 2, 4 do
		nOk = nOk and string.lower((SeedData.Get(named[i - 1].speciesId) :: any).Name)
			<= string.lower((SeedData.Get(named[i].speciesId) :: any).Name)
	end
	check(nOk, "name: A to Z by the name on the card", tags(named))

	local cycle, at = { "default" }, "default"
	for _ = 1, 5 do
		at = PlantInfo.NextSort(at)
		table.insert(cycle, at)
	end
	check(table.concat(cycle, ",") == "default,incomeHigh,incomeLow,rarity,name,default",
		"one press, the next order, round again", table.concat(cycle, ","))
	local plain = true
	for _, mode in ipairs(PlantInfo.SortModes) do
		local label = PlantInfo.SortLabels[mode]
		plain = plain and type(label) == "string" and string.match(label, "^[%w %-]+$") ~= nil
	end
	check(plain, "every order has a plain-word label (no arrow glyphs these fonts may box)")
end

--==============================================================================
-- 2. BASE INCOME
--==============================================================================
do
	local wrong = {}
	for _, species in ipairs(SeedData.Species) do
		for tier = 1, SeedData.TierCount do
			if PlantInfo.BaseIncome(species.Id, tier, true) ~= SeedData.IncomePerSecond(species, tier) then
				table.insert(wrong, species.Id .. " t" .. tier)
			end
			if PlantInfo.BaseIncome(species.Id, tier, false) ~= nil then
				table.insert(wrong, species.Id .. " pod t" .. tier .. " has a number")
			end
		end
	end
	check(#wrong == 0, "the thumbnail's number is IncomePerSecond -- tier, rarity, biome and flat bonus -- and a pod has none",
		table.concat(wrong, ", "))
	check(PlantInfo.BaseIncome("not_a_species", 3, true) == nil, "an unknown species shows nothing")
end

--==============================================================================
-- 3. MENU SIZE
--==============================================================================
do
	local M = GameConfig.MenuSize
	check(M.Default == "normal" and GameConfig.menuSizeScale("normal") == 1,
		"the default is today's size, scale 1")
	local modest, rising = true, true
	local last = 0
	for _, option in ipairs(M.Options) do
		modest = modest and option.Scale >= 1 and option.Scale <= 1.35
		rising = rising and option.Scale > last
		last = option.Scale
	end
	check(modest and rising and #M.Options >= 3, "modest larger options, in rising order")
	check(GameConfig.menuSizeScale("huge") == nil and GameConfig.menuSizeScale(nil) == nil,
		"anything that is not an option has no scale")
	check(GameConfig.nextMenuSize("normal") == "large" and GameConfig.nextMenuSize("larger") == "normal"
			and GameConfig.nextMenuSize("junk") == "normal",
		"the Settings button cycles the options and round again")
	check(ProfileSchema.Default().MenuSize == "normal", "a new profile has the default size")
	check(ProfileSchema.Sanitise({ Version = 2 }).MenuSize == "normal",
		"a save from before the setting loads at the default size")
	check(ProfileSchema.Sanitise({ Version = 2, MenuSize = "larger" }).MenuSize == "larger",
		"a saved choice is kept")
	check(ProfileSchema.Sanitise({ Version = 2, MenuSize = "gigantic" }).MenuSize == "normal",
		"and junk in the save reads as the default")

	local data = sourceOf(Server:FindFirstChild("PlayerDataService"))
	check(has(data, "GameConfig.menuSizeScale(id) == nil then\n\t\treturn false")
			and has(data, "if action ~= GameConfig.MenuSize.Action or type(payload) ~= \"string\" then")
			and has(data, "MenuSize = if GameConfig.menuSizeScale(profile.MenuSize) ~= nil")
			and count(data, "PlayerDataService.PublishMenuSize(player)") >= 3,
		"the server checks the choice, saves it on the profile the Walk Mode way, keeps it through a reset, and republishes it")
end

--==============================================================================
-- 3b. THE BAG PANEL AT A MENU SIZE
--==============================================================================
local TOPBAR, BAR_LEFT = 58, 208
local function rect(x: number, y: number, w: number, h: number)
	return { x = x, y = y, w = w, h = h }
end
local function screen(w: number, h: number, touch: boolean): any
	return {
		safe = Vector2.new(w, h - TOPBAR),
		touch = touch,
		keyboard = true,
		viewport = Vector2.new(w, h),
		topbar = rect(BAR_LEFT, 0, w - BAR_LEFT, TOPBAR),
		insetTop = TOPBAR,
	}
end
do
	local B = HudLayout.Config.Bag
	local cases = {
		{ "the owner's 801x392", screen(801, 392, true) },
		{ "Galaxy S22 Ultra 772x360", screen(772, 360, true) },
		{ "iPhone 11 896x414", screen(896, 414, true) },
		{ "desktop 1169x609", screen(1169, 609, false) },
		{ "desktop 1920x1080", screen(1920, 1080, false) },
	}
	for _, case in ipairs(cases) do
		local L = HudLayout.solve(case[2])
		do
			local base = { hotTop = L.hotbar.y, stripHidden = L.touch }
			local one = HudLayout.bag(L, base)
			local bigIn = table.clone(base) :: any
			bigIn.scale = 1.3
			local big = HudLayout.bag(L, bigIn)
			local tag = case[1]
			check(one.scale == 1, tag .. ": no menu size is scale 1")
			check(big.panel.x == one.panel.x and big.panel.y == one.panel.y
					and big.panel.w == one.panel.w and big.panel.h == one.panel.h,
				tag .. ": a larger size keeps the panel's footprint -- the HUD's free space")
			check(big.scale >= 1 and big.scale <= 1.3, tag .. ": drawn at the chosen size or less", big.scale)
			check(big.panel.w / big.scale >= B.MinW - 0.01 and big.panel.h / big.scale >= B.MinH - 0.01,
				tag .. ": never below the panel's minimum at its logical size", big.scale)
			check((big.rows >= 1 and big.catH >= B.CatMinH) or one.rows < 1,
				tag .. ": a whole row of tiles and the five category buttons still fit", string.format(
					"grid %.1f rows %d scale %.2f", big.grid.h, big.rows, big.scale))
		end
	end
	table.insert(notes, "Bag scale on the owner's phone at LARGER: " .. string.format("%.2f",
		HudLayout.bag(HudLayout.solve(screen(801, 392, true)), { hotTop = 0, stripHidden = true,
			scale = 1.3 }).scale))
end

-- A menu gui carrying the menu size's UIScale is not a TV to HudLayout.
do
	local gui = Instance.new("ScreenGui")
	gui.Parent = game:GetService("StarterGui")
	local plain = HudLayout.measure(gui)
	local marker = Instance.new("UIScale")
	marker.Name = HudLayout.TenFootName
	marker.Scale = 1.3
	marker.Parent = gui
	local saved = HudLayout.tenFootOverride
	HudLayout.tenFootOverride = false
	local scaled = HudLayout.measure(gui)
	HudLayout.tenFootOverride = true
	local tv = HudLayout.measure(gui)
	HudLayout.tenFootOverride = saved
	gui:Destroy()
	check(scaled.safe == plain.safe and scaled.tv == nil,
		"off a TV a menu's size UIScale changes nothing HudLayout measures -- the rail and HUD stay put",
		tostring(scaled.safe) .. " vs " .. tostring(plain.safe))
	check(tv.tv ~= nil, "on a TV the same gui still answers in TV units")
end

--==============================================================================
-- 4. THE CHASE BED
--==============================================================================
do
	local nest = sourceOf(Server:FindFirstChild("NestService"))
	-- Reshaped 2026-09-27 (the launch pass's warnings): the same count, now
	-- beside a WakingBy one. PursuedBy still counts CHASING only.
	check(has(nest, "publishPursuit = function()")
			and has(nest, "if target and not nest.busy then")
			and has(nest, "if nest.state == \"chasing\" then\n\t\t\t\tchasing[target] = (chasing[target] or 0) + 1")
			and has(nest, "local ok, err = pcall(publishPursuit)")
			and has(nest, "player:SetAttribute(GameConfig.Attributes.PursuedBy, nil)"),
		"the server counts guardians CHASING the player (not waking, throwing or walking home), every tick, and clears it on Init")
	local alert = client("AlertUI")
	check(count(alert, "SoundKit.chase(") == 2 and not has(alert, "onCarryChanged")
			and not has(alert, "ATTR.CarryingSpecies"),
		"the chase bed has one owner, and nothing in the alarm reads the carry any more")
	check(has(alert, "player:GetAttributeChangedSignal(ATTR.PursuedBy):Connect(onPursuitChanged)")
			and has(alert, "task.delay(GameConfig.Sfx.ChaseHoldSeconds, function()")
			and has(alert, "if token == chaseHold and chaseOn then"),
		"it follows PursuedBy, with a hold any change cancels")
	local SFX = GameConfig.Sfx
	check(SFX.ChaseHoldSeconds > 0 and SFX.ChaseHoldSeconds <= 2 and SFX.ChaseFadeOutSeconds > SFX.DuckSeconds
			and SFX.ChaseFadeInSeconds > 0 and SFX.ChaseFadeInSeconds < 1,
		"a short hold, a quick fade in, and a fade out the garden bed crosses")

	-- Behaviour, with the real bed: Edit plays sounds, but tweens do not advance.
	local kit = SoundKit :: any
	local realPlay, realStop = kit.play, kit.stop
	-- The real play below parents a SeedCue_ChaseBed to SoundService (Edit counts
	-- as a client), and every run's fresh SoundKit makes a new one: whatever this
	-- block adds is removed at its end, so runs leave nothing behind (2026-10-03:
	-- 57 had piled up).
	local before: { [Instance]: boolean } = {}
	for _, child in ipairs(SoundService:GetChildren()) do
		before[child] = true
	end
	local plays, stops = 0, 0
	kit.play = function(name: string, opts: any): any
		plays += 1
		return realPlay(name, opts)
	end
	kit.stop = function(name: string)
		stops += 1
		return realStop(name)
	end
	local ok, err = pcall(function()
		SoundKit.chase(true)
		check(plays == 1, "a pursuit starts the bed once", plays)
		local bed = SoundService:FindFirstChild("SeedCue_ChaseBed")
		local sounding = bed ~= nil and (bed :: Sound).IsPlaying
		if sounding then
			SoundKit.chase(true)
			check(plays == 1, "a second start while it plays does not restart it", plays)
			SoundKit.chase(false)
			check(stops == 0, "the end fades rather than cutting", stops)
			SoundKit.chase(true)
			check(plays == 1 and (bed :: Sound).IsPlaying,
				"a pursuit landing during the fade brings the same track back, not a restart", plays)
		else
			table.insert(notes, "the bed does not report IsPlaying in this Edit session, so the resume path was left to Play")
		end
		SoundKit.chase(false)
	end)
	kit.play, kit.stop = realPlay, realStop
	realStop("ChaseBed")
	local left = 0
	for _, child in ipairs(SoundService:GetChildren()) do
		if not before[child] and child:IsA("Sound") and string.sub(child.Name, 1, 8) == "SeedCue_" then
			child:Destroy()
			left += 1
		end
	end
	check(ok, "the chase bed calls ran clean", err)
	local stray = 0
	for _, child in ipairs(SoundService:GetChildren()) do
		if not before[child] and child:IsA("Sound") then
			stray += 1
		end
	end
	check(stray == 0, "and the bed it started is gone again: no Sound left in SoundService", "removed " .. left)
	check(has(sourceOf(Shared:FindFirstChild("SoundKit")), "if state == Enum.PlaybackState.Completed and token == chaseToken then"),
		"a fade that finishes stops the bed only if nothing has called since")
end

--==============================================================================
-- 5. THE PLOT'S NUMBERS
--==============================================================================
do
	local econ = sourceOf(Server:FindFirstChild("EconomyService"))
	local pay = string.match(econ, "local function payEveryone%(%)(.-)\nend") or ""
	local publishAt = string.find(pay, "publishGarden(player, rate)", 1, true)
	local sinceAt = string.find(pay, "local since = lastPaid[player]", 1, true)
	check(publishAt ~= nil and sinceAt ~= nil and publishAt < sinceAt
			and has(pay, "local rate = EconomyService.RateFor(player)"),
		"the sign's income is the rate the tick pays, published every tick before the pay check")
	check(has(econ, "not PlantService.GardenRestored(plot) then")
			and has(econ, "local boost = withPass(player, 1)")
			and count(econ, "PassService.CashMultiplier") == 1,
		"nothing before the garden is restored; the boost is the rate's own; the pass is still read in one place")
	local plot = sourceOf(Server:FindFirstChild("PlotService"))
	local clear = string.match(plot, "local function clearPlot%(plot: Model%)(.-)\nend") or ""
	check(has(clear, "ATTR.GardenGrown, nil") and has(clear, "ATTR.GardenPods, nil")
			and has(clear, "ATTR.GardenIncome, nil") and has(clear, "ATTR.GardenBoost, nil"),
		"a released plot's numbers go with its owner")
end

--==============================================================================
-- 6. WIRING
--==============================================================================
do
	local bag = client("LoadoutUI")
	local model = string.match(sourceOf(Shared:FindFirstChild("InventoryModel")) or "", "function InventoryModel%.sort(.-)\nend\n") or ""
	-- 2026-10-10: the owner asked for SORT (SortSpec); INCOME is this old order.
	check(has(model, "PlantInfo.BaseIncome(item.speciesId, item.tier, true)")
			and has(model, "local favourite = if g.favourite then 0 else 1")
			and has(model, "rank[g] = { favourite, category, a, b, c, firstOrder(g), 0 }")
			and has(bag, "panel.state.sort)") and not has(bag, "PlantInfo.Sort("),
		"the Bag's order (2026-10-03): favourites first, plants by base income -- under the SORT button's INCOME since "
			.. "2026-10-10")
	check(has(bag, "scale = UIKit.menuScale(),") and has(bag, "modal.setUserScale(bag.scale)")
			and has(bag, "UIKit.onMenuSize(layoutBag)"),
		"the Bag takes the menu size on its own panel and re-lays out when it changes")
	local garden = client("GardenUI")
	-- MY PLANTS (2026-10-04): earners first by income (placement id on a tie),
	-- pods after by their clock; a selection that has gone is let go. Since
	-- 2026-10-10 the player's SORT picks the earners' order (SortSpec); income
	-- is the tie-break of every one.
	check(has(garden, "if a.rate ~= b.rate then\n\t\treturn a.rate > b.rate")
			and has(garden, "return fresh(a) < fresh(b)") and has(garden, "return e.id or 0")
			and has(garden, "return (a.hatchAt or 0) < (b.hatchAt or 0)")
			and has(garden, "if selectedKey and not byKey[selectedKey :: string] then"),
		"MY PLANTS orders by income with stable ties, pods by their clock, and drops a stale selection")
	for _, name in ipairs({ "GardenUI", "IndexUI", "ShopUI", "MarigoldShopUI", "SettingsUI" }) do
		check(has(client(name), "UIKit.menuGui(gui"), name .. " takes the menu size on its own gui")
	end
	for _, name in ipairs({ "SellUI", "OfflineUI" }) do
		check(has(client(name), "modal.followMenuSize()"), name .. " takes the menu size on its panel")
	end
	for _, name in ipairs({ "CashUI", "WorldClock", "ActionToastUI", "PlotTeleportUI", "BiomeGuideUI",
		"TutorialUI", "RailDrawerUI", "WalkModeUI", "AlertUI" }) do
		check(not has(client(name), "menuGui") and not has(client(name), "followMenuSize"),
			name .. " is HUD and never takes the menu size")
	end
	local settings = client("SettingsUI")
	check(has(settings, "UIKit.cycleButton(titleBar, \"MENU SIZE\", 4)")
			and has(settings, "UIKit.setMenuSize(id)")
			and has(settings, "channel:FireServer(GameConfig.MenuSize.Action, id)")
			and not has(settings, "Instance.new(\"RemoteEvent\")"),
		"Settings sets the size at once and saves it on the remote the HUD already has")
end

local summary = if #notes > 0 then "\n  note: " .. table.concat(notes, "\n  note: ") else ""
if #fails > 0 then
	return ("UsabilityAudioSpec: %d passed, %d FAILED\n  %s%s"):format(pass, #fails, table.concat(fails, "\n  "), summary)
end
return ("UsabilityAudioSpec: %d passed, 0 failed%s"):format(pass, summary)
