--!nocheck
--==============================================================================
-- Steal a Seed :: RarityCardsSpec (2026-10-10, the owner's rarity cards)
--
-- The owner: "plan me a color by rarity, lets say mythic, their background must
-- be white, it also applies on equipments and traps too"; "add shine effect";
-- "the colorful one is for secret best pick for divine is white". In Edit:
--
--   1. the cards: Codex's three uploads under the owner's ids at the coral's
--      stud spacing; Mythic and Divine pearl, Secret holo, Uncommon to
--      Legendary as before, Common plain; no kind's card for bats and traps
--   2. bats and traps: each a Rarities id rising with price along its shelf,
--      bats Common to Mythic, traps Uncommon to Mythic; looks only -- the
--      face's word, card, edge and accent; the menu's Rarity and Type lines
--   3. the shine: the three rarest have one and nothing else does; a handle
--      shows for them and hides for anything else, a plain card and reduced
--      motion; runs only when switched on; crosses once a cycle and rests
--      clear; a card further right starts later; a step moves it
--   4. a Bag tile: the shine over the studs and under the preview (made right
--      after them, same ZIndex); the white card's denser band; shown for a
--      studded Mythic only, never a Rare, a restoring tile or a plain card
--   5. the wiring: MY PLANTS and the TOP CREATURES board make the shine right
--      after their studs and switch it with their other lights; the strip and
--      the Bag hand a bat's or trap's accent and edge on
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local InventoryModel = require(Shared:WaitForChild("InventoryModel"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local InventoryTile = require(Shared:WaitForChild("InventoryTile"))

local BAG = GameConfig.BagLook
local FX = GameConfig.RarityFX
local EDGE = GameConfig.RarityEdge
local HOT = GameConfig.Hotbar

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

local function item(kind, speciesId, tier, extra)
	local i = { ref = "i:1", kind = kind, speciesId = speciesId, tier = tier, hatched = kind == "plant",
		sealed = false, restoring = false, count = 1, worn = false, favourite = false, order = 1 }
	for k, v in pairs(extra or {}) do
		i[k] = v
	end
	return i
end

local function near(a, b)
	return math.abs(a - b) < 1e-6
end

local layer = Instance.new("ScreenGui")
layer.Name = "ZZRarityCardsSpec"
layer.Archivable = false
local realStill = RarityFX.still

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE CARDS
	--==========================================================================
	say("-- the cards --")
	local S = BAG.Studs
	check(S.pearl and S.pearl.image == "rbxassetid://72726318027556"
			and S.holo and S.holo.image == "rbxassetid://78921871175240"
			and S.obsidian and S.obsidian.image == "rbxassetid://94572104024955",
		"Codex's three under the owner's upload ids: pearl, holo, obsidian")
	check(S.pearl.pitch == S.coral.pitch and S.holo.pitch == S.coral.pitch and S.obsidian.pitch == S.coral.pitch
			and not S.pearl.wide and not S.holo.wide and not S.obsidian.wide,
		"the coral's stud spacing (measured the same), a centred window like the six, never wide")
	check(S.pearl.light == true and type(S.pearl.words) == "number" and S.pearl.words < BAG.StudWordsTransparency
			and S.holo.words == nil and S.holo.light == nil,
		"the white card: a denser band under its words and a dark selection line; the holo neither")
	local noFallback = {}
	for key, spec in pairs(S) do
		if not ((spec.top and spec.bottom) or spec.stops) then
			table.insert(noFallback, key)
		end
	end
	check(#noFallback == 0, "every card has its solid fallback, drawn until the picture loads",
		table.concat(noFallback, ", "))
	local R = BAG.StudsByRarity
	check(R.Mythic == "pearl" and R.Divine == "pearl" and R.Secret == "holo",
		"Mythic and Divine on the white card, Secret on the colourful holo")
	check(R.Uncommon == "lime" and R.Rare == "sky" and R.Epic == "purple" and R.Legendary == "gold"
			and R.Common == nil,
		"Uncommon to Legendary as before; a Common keeps the plain card")
	local missing = {}
	for rarity, key in pairs(R) do
		if not S[key] or GameConfig.RarityTier[rarity] == nil then
			table.insert(missing, rarity)
		end
	end
	check(#missing == 0, "every mapped rarity is a Rarities id and its card one of the uploads",
		table.concat(missing, ", "))
	local K = BAG.StudsByKind
	check(K.equipment == nil and K.tickets == "purple" and K.trail == "rainbow",
		"no kind's card for bats and traps any more; tickets and the trail keep theirs")

	--==========================================================================
	-- 2. BATS AND TRAPS
	--==========================================================================
	say("-- bats and traps --")
	local tierOf = GameConfig.RarityTier
	local bad = {}
	local shelves = { bat = {}, trap = {} }
	for _, w in ipairs(WeaponData.Items) do
		if type(w.Rarity) ~= "string" or tierOf[w.Rarity] == nil then
			table.insert(bad, w.Id .. "=" .. tostring(w.Rarity))
		end
		local shelf = shelves[w.Category]
		if shelf then
			table.insert(shelf, w)
		else
			table.insert(bad, w.Id .. " on no shelf")
		end
	end
	check(#bad == 0 and #WeaponData.Items == 11, "all 11 have a rarity, a Rarities id", table.concat(bad, ", "))
	for _, cat in ipairs({ "bat", "trap" }) do
		local list = shelves[cat]
		table.sort(list, function(a, b)
			return a.Price < b.Price
		end)
		local rising = #list > 0
		for i = 2, #list do
			if tierOf[list[i].Rarity] <= tierOf[list[i - 1].Rarity] then
				rising = false
			end
		end
		check(rising, cat .. "s: the rarity rises with the price along the shelf")
	end
	local bats, traps = shelves.bat, shelves.trap
	check(#bats == 6 and #traps == 5 and bats[1].Rarity == "Common" and bats[6].Rarity == "Mythic"
			and traps[1].Rarity == "Uncommon" and traps[5].Rarity == "Mythic",
		"bats Common to Mythic, traps Uncommon to Mythic (the plan the owner saw)")

	local wrongFaces = {}
	for _, w in ipairs(WeaponData.Items) do
		local f = InventoryModel.face(item("weapon", nil, 1, { weaponId = w.Id }))
		local fx = FX[w.Rarity]
		local wantAccent = if fx then fx.Edge else GameConfig.RarityColor[w.Rarity]
		local word = if w.Category == "trap" then "trap" else "bat"
		if f.rarity ~= w.Rarity or f.variant ~= w.Rarity or not f.variantIsRarity or f.studs ~= R[w.Rarity]
			or f.edge ~= EDGE.Colours[w.Rarity] or f.accent ~= wantAccent or f.category ~= "equipment"
			or not string.find(f.search, word, 1, true)
			or not string.find(f.search, string.lower(w.Rarity), 1, true) then
			table.insert(wrongFaces, w.Id)
		end
	end
	check(#wrongFaces == 0, "every bat and trap: its rarity as the word, its card, its still edge (none for the "
		.. "three rarest), its accent; found by 'bat' or 'trap' and by its rarity", table.concat(wrongFaces, ", "))
	local comet = InventoryModel.face(item("weapon", nil, 1, { weaponId = "comet_bat" }))
	local starlock = InventoryModel.face(item("weapon", nil, 1, { weaponId = "starlock_trap" }))
	check(comet.studs == "pearl" and starlock.studs == "pearl" and comet.edge == nil and starlock.edge == nil
			and RarityFX.edgeColour(comet.rarity) == FX.Mythic.Edge,
		"Comet Bat and Starlock Anchor: Mythic, on the white card, with Mythic's own edge")
	local rootwood = InventoryModel.face(item("weapon", nil, 1, { weaponId = "rootwood_bat" }))
	check(rootwood.rarity == "Common" and rootwood.studs == nil and rootwood.edge == EDGE.Colours.Common,
		"Rootwood Bat: Common, the plain card, the grey edge")
	local dunes = item("weapon", nil, 1, { weaponId = "dunesnap_trap" })
	local seen = {}
	for _, l in ipairs(InventoryModel.details(dunes, InventoryModel.face(dunes), nil, nil, false)) do
		seen[l.key] = l
	end
	check(seen.Rarity and seen.Rarity.value == "Rare" and seen.Rarity.rarity == "Rare" and seen.Type
			and seen.Type.value == "Trap",
		"the menu: a Rarity line (styled by its id) and a Type line, the word the tile used to say")
	local trail = InventoryModel.face(item("trail", nil, 1))
	local tickets = InventoryModel.face(item("ticket", nil, 1))
	check(trail.rarity == nil and trail.edge == nil and trail.studs == "rainbow" and tickets.rarity == nil
			and tickets.studs == "purple",
		"the trail and tickets: no rarity, their own cards")

	--==========================================================================
	-- 3. THE SHINE
	--==========================================================================
	say("-- the shine --")
	local styled = RarityFX.style("Mythic") and RarityFX.style("Divine") and RarityFX.style("Secret")
	check(styled and RarityFX.style("Mythic").shine and RarityFX.style("Divine").shine
			and RarityFX.style("Secret").shine and RarityFX.style("Legendary") == nil,
		"the three rarest each have a shine; no other rarity has a style")
	local white = Color3.new(1, 1, 1)
	local mythicWhite = true
	for _, c in ipairs(FX.Mythic.Shine) do
		if c ~= white then
			mythicWhite = false
		end
	end
	check(not mythicWhite and FX.Divine.Shine[1] ~= white,
		"neither white card's shine is plain white (it would vanish on the card)")

	RarityFX.still = function()
		return false
	end
	local face = Instance.new("Frame")
	face.Size = UDim2.fromOffset(100, 120)
	face.Parent = layer
	local h = RarityFX.shine(face, 8, 3)
	check(h.kind == "shine" and h.frame.Parent == face and not h.frame.Visible and h.frame.ZIndex == 3,
		"a shine is made hidden, on the card's face, at the ZIndex given")
	RarityFX.setShine(h, "Mythic")
	check(h.frame.Visible and near(h.gradient.Offset.X, 1) and h.gradient.Rotation == FX.Shine.Rotation,
		"a Mythic's: shown, resting clear past the right edge, slanted")
	check(not RarityFX.isRunning(h), "not running until its owner switches it on")
	RarityFX.setActive(h, true)
	check(RarityFX.isRunning(h), "switched on: running")
	RarityFX.setShine(h, "Rare")
	check(not h.frame.Visible and not RarityFX.isRunning(h), "a Rare: no shine, nothing runs")
	RarityFX.setShine(h, nil)
	check(not h.frame.Visible and not RarityFX.isRunning(h), "a plain card: none")
	RarityFX.still = function()
		return true
	end
	RarityFX.setShine(h, "Secret")
	check(not h.frame.Visible and not RarityFX.isRunning(h), "reduced motion: no shine at all")
	RarityFX.still = function()
		return false
	end

	-- Times well inside the windows: a modulo of a float clock is never exact
	-- at a cycle's edge.
	local cycle, sweep, wave = FX.CycleSeconds, FX.Shine.Sweep, FX.Shine.Wave
	check(near(RarityFX.shineOffset(sweep / 4, 0), -0.5) and near(RarityFX.shineOffset(sweep / 2, 0), 0)
			and near(RarityFX.shineOffset(sweep + 0.3, 0), 1) and near(RarityFX.shineOffset(cycle - 0.3, 0), 1)
			and near(RarityFX.shineOffset(cycle + sweep / 2, 0), 0),
		"crosses -1 to 1 in Sweep seconds at the start of each cycle, then rests clear; again the next cycle")
	check(near(RarityFX.shineOffset(wave + sweep / 4, 1000), -0.5) and near(RarityFX.shineOffset(sweep / 4, 1000), 1),
		"a card 1000 px further right starts Wave seconds later")

	RarityFX.setShine(h, "Divine")
	RarityFX.setActive(h, true)
	local x = h.frame.AbsolutePosition.X
	-- Later than any clock a step has seen (the step keeps its own last time).
	local start = 1e6 * cycle + math.clamp(x / 1000, 0, 2) * wave
	RarityFX.step(start + sweep / 2)
	local mid = h.gradient.Offset.X
	RarityFX.step(start + sweep + 0.2)
	local after = h.gradient.Offset.X
	check(near(mid, 0) and near(after, 1), "a step moves a running shine: mid-sweep at the middle, then clear",
		string.format("%.3f / %.3f", mid, after))
	RarityFX.forget(h)
	check(not RarityFX.isRunning(h), "forgotten: never stepped again")

	--==========================================================================
	-- 4. A BAG TILE
	--==========================================================================
	say("-- a Bag tile --")
	local tile = InventoryTile.build(layer, HOT, 5)
	local function paint(extra)
		local p = { name = "Comet Bat", variant = "Mythic", variantColour = white, favourite = false, held = false,
			restoring = false, rarity = "Mythic", variantIsRarity = true, studs = "pearl" }
		for k, v in pairs(extra or {}) do
			p[k] = v
		end
		if p.plain then
			p.studs = nil
		end
		InventoryTile.paint(tile, HOT, p)
	end
	paint()
	local iStuds, iShine = nil, nil
	for i, c in ipairs(tile.back:GetChildren()) do
		if c.Name == "Studs" then
			iStuds = i
		elseif c.Name == "RarityShine" then
			iShine = i
		end
	end
	check(iStuds ~= nil and iShine ~= nil and iShine > iStuds
			and tile.fxShine.frame.ZIndex == tile.studs.image.ZIndex,
		"the shine lies over the studs (made right after them, the same ZIndex), under the preview")
	check(tile.fxShine.frame.Visible and tile.words.Visible
			and near(tile.words.BackgroundTransparency, BAG.Studs.pearl.words),
		"a Mythic on the white card: its shine, and the denser band under its words")
	paint({ rarity = "Rare", variantIsRarity = false, studs = "sky" })
	check(not tile.fxShine.frame.Visible and near(tile.words.BackgroundTransparency, BAG.StudWordsTransparency),
		"a Rare on sky: no shine, the usual band")
	paint({ restoring = true })
	check(not tile.fxShine.frame.Visible, "a tile still restoring: no shine")
	paint({ plain = true })
	check(not tile.fxShine.frame.Visible and not tile.words.Visible, "a plain card: no shine, no band")
	paint({ rarity = "Secret", studs = "holo" })
	InventoryTile.animate(tile, true)
	check(tile.fxShine.frame.Visible and RarityFX.isRunning(tile.fxShine), "on screen, a Secret's shine runs")
	InventoryTile.animate(tile, false)
	check(not RarityFX.isRunning(tile.fxShine), "the Bag shut: it stops")

	--==========================================================================
	-- 5. THE WIRING
	--==========================================================================
	say("-- the wiring --")
	local Client = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	local function src(parent, name)
		local s = parent:FindFirstChild(name)
		return if s then s.Source else ""
	end
	local function order(text, ...)
		local at = 0
		for _, needle in ipairs({ ... }) do
			local found = string.find(text, needle, at + 1, true)
			if not found then
				return false
			end
			at = found
		end
		return true
	end
	local garden = src(Client, "GardenUI")
	check(order(garden, "local studs = UIKit.studCard(face, 8, Z + 1)", "local fxShine = RarityFX.shine(face, 8, Z + 1)",
			"local words = MenuKit.frame(face, \"Words\"")
			and string.find(garden, "RarityFX.setActive(c.fxShine, inView)", 1, true)
			and string.find(garden, "RarityFX.setShine(c.fxShine, if studded and not e.restoring then face.rarity else nil)",
				1, true)
			and string.find(garden, "c.innerRing.Color = if spec and spec.light then LOOK.Ink else WHITE", 1, true),
		"MY PLANTS: the shine right after the studs, switched with the card's lights; the white card's dark line")
	local plot = src(Shared, "PlotShowcaseView")
	check(order(plot, "local studs = UIKit.studCard(face, 10, Z + 1)", "local shineFX = RarityFX.shine(face, 10, Z + 1)",
			"local words = MenuKit.frame(face, \"Words\"")
			and string.find(plot, "RarityFX.setActive(card.shineFX, live)", 1, true)
			and string.find(plot, "RarityFX.forget(card.shineFX)", 1, true)
			and string.find(plot, "RarityFX.setShine(card.shineFX, if studded then content.rarity else nil)", 1, true),
		"the TOP CREATURES board: the shine right after the studs, live only near, forgotten with the board")
	local loadout = src(Client, "LoadoutUI")
	check(string.find(loadout,
			"accent = if item and (item.kind == \"plant\" or item.kind == \"weapon\") and face then face.accent else nil",
			1, true)
			and string.find(loadout,
				"accent = if group.category == \"plants\" or group.category == \"equipment\" then face.accent else nil",
				1, true),
		"the strip and the Bag hand a bat's or trap's accent on, as a grown plant's")

	--==========================================================================
	-- 6. MARIGOLD'S SHOP (2026-10-10, the owner: "yes do the marigold shop
	--    cards too")
	--==========================================================================
	say("-- Marigold's shop --")
	local shop = src(Client, "MarigoldShopUI")
	check(order(shop, "UIKit.gradient(fill, pal.Card:Lerp(WHITE, 0.10), pal.Card:Lerp(BLACK, 0.22))",
			"local studs = UIKit.studCard(fill, 10, 5)", "local spec = studs.set((LOOK.StudsByRarity :: any)[item.Rarity])",
			"local fxShine = RarityFX.shine(fill, 10, 5)", "local topLight = Instance.new(\"Frame\")",
			"local stage = Instance.new(\"Frame\")"),
		"each card: its rarity's studs first in the fill, the shine right after, both under the bevel and the stage")
	check(string.find(shop, "RarityFX.setShine(fxShine, if spec then item.Rarity else nil)", 1, true)
			and string.find(shop, "holder.BackgroundColor3 = RarityFX.edgeColour(item.Rarity) or stillEdge or pal.CardEdge",
				1, true)
			and string.find(shop, "local fxEdge = RarityFX.edge(holder, 12, 9)", 1, true)
			and string.find(shop, "RarityFX.setEdge(fxEdge, item.Rarity, true)", 1, true),
		"the ring in the rarity's colour (Mythic's own), the shine and the edge light on the three rarest")
	check(string.find(shop, "rarityLabel.Text = string.upper(item.Rarity)", 1, true)
			and string.find(shop, "local fxText = RarityFX.text(rarityLabel, rarityLine)", 1, true)
			and string.find(shop, "card.rarity.Position = UDim2.fromOffset(10, 10 + art + (if narrow then 2 else 4))",
				1, true),
		"the rarity's word under the picture, moving on the three rarest, laid out on a phone too")
	check(string.find(shop, "backing.BackgroundTransparency = spec.words or LOOK.StudWordsTransparency", 1, true)
			and string.find(shop, "backing.Parent = blurb", 1, true),
		"on a studded card the sentence stands on the Bag's ink backing (the white card's denser)")
	check(string.find(shop, "RarityFX.setActive(card.fxText, want)", 1, true)
			and string.find(shop, "RarityFX.setActive(card.fxEdge, want)", 1, true)
			and string.find(shop, "RarityFX.setActive(card.fxShine, want)", 1, true),
		"the lights move only while the shop is open")

	--==========================================================================
	-- 7. THE INDEX (2026-10-10, the owner: "also apply them on index, and
	--    their background too")
	--==========================================================================
	say("-- the Index --")
	local index = src(Client, "IndexUI")
	check(order(index, "local tint = MenuKit.cardFace(face)", "local studs = UIKit.studCard(face, 8, Z + 1)",
			"local fxShine = RarityFX.shine(face, 8, Z + 1)",
			"local well = MenuKit.frame(face, \"Preview\", Z + 2, LOOK.Window, 0, 6)"),
		"each Index card: its rarity's studs over the plain face, the shine right after, both under the window")
	check(string.find(index, "local spec = c.studs.set((STUD_LOOK.StudsByRarity :: any)[face.rarity])", 1, true)
			and string.find(index, "c.well.BackgroundTransparency = if studded and known then 1 else 0", 1, true)
			and string.find(index, "RarityFX.setShine(c.fxShine, if studded then face.rarity else nil)", 1, true),
		"found or not (the rarity is on every card); a found plant stands on its studs, an undiscovered one in the dark")
	check(string.find(index, "c.words.Visible = studded", 1, true)
			and string.find(index, "c.name.TextColor3 = if studded then (if known then WHITE else UNKNOWN_ON_STUDS)", 1, true)
			and string.find(index, "c.edge.Color = rare or (if studded then LOOK.Ink else LOOK.CardEdge)", 1, true),
		"its words light on the Bag's ink backing; the ink keyline round a studded card")
	local _, actives = string.gsub(index, "RarityFX%.setActive%(c%.fxShine, ", "")
	check(actives == 3, "the shine moves only in view and stops with the panel (every place the edge does)", actives)
end)

RarityFX.still = realStill
layer:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nRarityCardsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
