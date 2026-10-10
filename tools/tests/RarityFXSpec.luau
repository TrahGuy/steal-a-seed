--!nocheck
--==============================================================================
-- Steal a Seed :: RarityFXSpec
--
-- The owner's inventory pass (2026-10-03): Mythic, Divine and Secret read in
-- the Bag and on the strip -- the rarity word moves, the card's edge carries a
-- light -- and nothing a sealed pod hides comes out through it. Edit mode:
-- stand-in labels and cards in a throwaway ScreenGui; RarityFX.still is
-- swapped for the reduced-motion half and put back.
--
--   1. what may be said: a face's rarity is the form's for a grown plant, the
--      shell's for a Secret or Rain pod, nothing for any ordinary pod (every
--      species), a plant still in its roll, or equipment; the Rarity line
--   2. the styles: three ids and no others ("Mythical" is not one)
--   3. the word: styled, plain again, Secret's italic and light keyline
--   4. the edge: shown, put out, running only when switched on, a step turns
--      only what runs and only under a visible gate, forget drops it
--   5. reduced motion: the same colours, still; nothing runs
--   6. a Bag tile and a strip slot: the light gives way to in hand, target,
--      pending, restoring and a flash; the in-hand diamond; empties stay plain
--   7. the other five, still (2026-10-10, the owner: "yes, add rarity edges"):
--      a GROWN plant from Common to Legendary wears its rarity's colour -- a
--      band inside a Bag tile's keyline and an Almanac card's, the strip slot's
--      own edge -- and nothing else does; held, target, pending and a flash
--      outrank it, restoring keeps it; legible at a phone's 85%
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local InventoryModel = require(Shared:WaitForChild("InventoryModel"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local InventoryTile = require(Shared:WaitForChild("InventoryTile"))
local HotbarCard = require(Shared:WaitForChild("HotbarCard"))

local HOT = GameConfig.Hotbar
local FX = GameConfig.RarityFX

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

local layer = Instance.new("ScreenGui")
layer.Name = "ZZRarityFXSpec"
layer.Archivable = false
local realStill = RarityFX.still

local ok, err = pcall(function()
	--==========================================================================
	-- 1. WHAT MAY BE SAID
	--==========================================================================
	say("-- what may be said --")
	local f = InventoryModel.face(item("plant", "gloomlotus", 4))
	check(f.rarity == "Mythic" and not f.variantIsRarity and f.variant ~= "Mythic",
		"a grown Mythic with a size: the rarity is known, the line still says its size", f.variant)
	f = InventoryModel.face(item("plant", "drizzlet", 1))
	check(f.rarity == "Mythic" and f.variantIsRarity and f.variant == "Mythic",
		"an unsized Rain form: the line IS the word Mythic")
	f = InventoryModel.face(item("plant", "tempestoak", 1))
	check(f.rarity == "Divine" and f.variantIsRarity and f.variant == "Divine", "a Thunderstorm form: Divine")
	f = InventoryModel.face(item("plant", "snarlbloom", 1))
	check(f.rarity == "Secret" and f.variantIsRarity and f.variant == "Secret",
		"a Secret: the word Secret and no size tier")
	f = InventoryModel.face(item("plant", "gloomlotus", 4))
	check(f.accent == FX.Mythic.Edge, "the three rarest's accent bar is their inventory edge colour")
	f = InventoryModel.face(item("plant", "nubkin", 2))
	check(f.rarity == "Common" and f.accent == GameConfig.RarityColor.Common,
		"every other rarity keeps its RarityColor accent")

	-- No ordinary pod ever says what is inside it -- every species there is.
	local leaks = {}
	local all = {}
	for _, list in ipairs({ SeedData.Species or {}, SeedData.SecretSpecies or {}, SeedData.RainSpecies or {} }) do
		for _, s in ipairs(list) do
			all[s.Id] = s
		end
	end
	local podsSeen, secretPods, rainPods = 0, 0, 0
	for id, s in pairs(all) do
		local pf = InventoryModel.face(item("pod", id, 3, { hatched = false }))
		podsSeen += 1
		if s.Secret == true then
			secretPods += 1
			if pf.rarity ~= "Secret" then
				table.insert(leaks, id .. "->" .. tostring(pf.rarity))
			end
		elseif SeedData.RainPodOf(s) then
			rainPods += 1
			if pf.rarity ~= SeedData.RainPodOf(s).Rarity then
				table.insert(leaks, id .. "->" .. tostring(pf.rarity))
			end
		elseif pf.rarity ~= nil or pf.variantIsRarity then
			table.insert(leaks, id .. "->" .. tostring(pf.rarity))
		end
	end
	check(#leaks == 0 and podsSeen >= 20 and secretPods >= 1 and rainPods >= 3,
		string.format("%d pods: an ordinary pod has no rarity; a Secret pod says Secret; a Rain pod its pod's",
			podsSeen), table.concat(leaks, ", "))
	f = InventoryModel.face(item("pod", "gloomlotus", 4, { hatched = false }))
	check(f.rarity == nil and f.name == "Tanglemire pod",
		"a Mythic inside an ordinary pod shows no rarity: only its biome's pod (the Pod Guide, 2026-10-09)")
	f = InventoryModel.face(item("pod", "drizzlet_colossal", 7, { hatched = false }))
	check(f.rarity == "Mythic" and not f.variantIsRarity and f.variant == "Colossal",
		"Rain pod 2 shows its size; its rarity is the shell's own")
	f = InventoryModel.face(item("pod", "gloomlotus", 4, { hatched = true, sealed = true }))
	check(f.rarity == nil, "a plant still in its roll is its pod: no rarity")
	local weaponId = require(Shared:WaitForChild("WeaponData")).Items[1].Id
	f = InventoryModel.face(item("weapon", nil, 1, { weaponId = weaponId }))
	check(f.rarity == nil and not f.variantIsRarity, "equipment has no rarity")
	local lines = InventoryModel.details(item("pod", "gloomlotus", 4, { hatched = false }),
		InventoryModel.face(item("pod", "gloomlotus", 4, { hatched = false })), nil, nil, false)
	local rarityLine = nil
	for _, l in ipairs(lines) do
		if l.key == "Rarity" or l.rarity ~= nil then
			rarityLine = l
		end
	end
	check(rarityLine == nil, "an ordinary pod's details have no Rarity line")
	lines = InventoryModel.details(item("plant", "drizzlet", 1), InventoryModel.face(item("plant", "drizzlet", 1)),
		nil, nil, false)
	check(lines[1].key == "Rarity" and lines[1].rarity == "Mythic", "a plant's Rarity line names its id for styling")

	--==========================================================================
	-- 2. THE STYLES
	--==========================================================================
	say("\n-- the styles --")
	check(RarityFX.style("Mythic") and RarityFX.style("Divine") and RarityFX.style("Secret")
			and not RarityFX.style("Mythical") and not RarityFX.style("Legendary") and not RarityFX.style(nil),
		"three ids, the canonical ones; nothing for Mythical, Legendary or none")
	check(table.find(GameConfig.Rarities, "Mythic") and not table.find(GameConfig.Rarities, "Mythical"),
		"no rarity was created or renamed")
	check(FX.CycleSeconds >= 3 and FX.CycleSeconds <= 4 and FX.StepSeconds >= 1 / 60,
		"one slow cycle every 3-4 s, stepped at most 30-60 times a second", FX.CycleSeconds)
	check(RarityFX.edgeColour("Mythic") == FX.Mythic.Edge and RarityFX.edgeColour("Rare") == nil,
		"an edge colour for the three only")

	--==========================================================================
	-- 3. THE WORD
	--==========================================================================
	say("\n-- the word --")
	layer.Parent = StarterGui
	RarityFX.still = function()
		return false
	end
	local label = Instance.new("TextLabel")
	label.Font = Enum.Font.FredokaOne
	label.ZIndex = 9 -- a tile's variant line's layer
	label.Parent = layer
	local line = Instance.new("UIStroke")
	line.Color = Color3.new(0, 0, 0)
	line.Parent = label
	local plainFont = label.FontFace
	local t = RarityFX.text(label, line)
	RarityFX.setText(t, "Mythic", Color3.new(1, 0, 0))
	check(t.gradient.Enabled and label.TextColor3 == Color3.new(1, 1, 1) and t.gradient.Rotation == 0
			and line.Color == FX.Mythic.Outline and t.animated,
		"Mythic: the word white under its crimson gradient, its keyline crimson-dark, animated")
	label.Text = "Secret"
	RarityFX.setText(t, "Secret", Color3.new(1, 0, 0))
	local halo = label:FindFirstChild("RarityHalo")
	check(label.FontFace.Style == Enum.FontStyle.Italic and halo and halo.Visible and halo.Text == "Secret"
			and halo.FontFace == label.FontFace and halo:FindFirstChildOfClass("UIStroke").Color == FX.Secret.Outline
			and halo.ZIndex < label.ZIndex and line.Transparency == 1,
		"Secret: the toast's italic; its LIGHT keyline on a twin behind the word, out of the gradient's reach")
	RarityFX.setText(t, nil, Color3.fromRGB(10, 20, 30))
	check(not t.gradient.Enabled and label.TextColor3 == Color3.fromRGB(10, 20, 30)
			and label.FontFace == plainFont and line.Color == Color3.new(0, 0, 0) and line.Transparency == 0
			and not halo.Visible and not t.animated,
		"a size word: plain again, its own colour, font and keyline, no halo")
	RarityFX.setText(t, "Legendary", Color3.fromRGB(10, 20, 30))
	check(not t.gradient.Enabled, "Legendary keeps its plain look")

	--==========================================================================
	-- 4. THE EDGE AND THE CLOCK
	--==========================================================================
	say("\n-- the edge and the clock --")
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(64, 64)
	card.Parent = layer
	local e = RarityFX.edge(card, 6, 3)
	check(e.frame.Parent == card and e.stroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border
			and e.frame.Size == UDim2.fromScale(1, 1) and not e.frame.Visible,
		"the light's frame lies exactly on the card, its stroke on the BORDER, hidden until asked")
	RarityFX.setEdge(e, "Divine", true)
	check(e.frame.Visible and not RarityFX.isRunning(e), "shown, but not running until switched on")
	RarityFX.setActive(e, true)
	check(RarityFX.isRunning(e), "switched on: running")
	local before = RarityFX.runningCount()
	e.gradient.Rotation = -1
	RarityFX.step(1000.9)
	check(e.gradient.Rotation >= 0 and e.gradient.Rotation < 360, "a step turns it", e.gradient.Rotation)
	local turned = e.gradient.Rotation
	RarityFX.step(1000.91)
	check(e.gradient.Rotation == turned, "and never twice within StepSeconds")
	e.gate = card
	card.Visible = false
	e.gradient.Rotation = -1
	RarityFX.step(1001.9)
	check(e.gradient.Rotation == -1, "under a hidden gate nothing moves")
	card.Visible = true
	RarityFX.setEdge(e, "Divine", false)
	check(not e.frame.Visible and not RarityFX.isRunning(e), "put out (a state outranks it): hidden, not running")
	RarityFX.setEdge(e, "Uncommon", true)
	check(not e.frame.Visible and not RarityFX.isRunning(e), "an ordinary rarity has no light")
	RarityFX.setEdge(e, "Mythic", true)
	RarityFX.forget(e)
	check(not RarityFX.isRunning(e) and RarityFX.runningCount() == before - 1, "forget drops it")
	RarityFX.setActive(t, true)
	RarityFX.setText(t, "Mythic", Color3.new(1, 1, 1))
	label:Destroy()
	RarityFX.step(1003)
	check(not RarityFX.isRunning(t), "a word whose label has gone is dropped by the next step")

	--==========================================================================
	-- 5. REDUCED MOTION
	--==========================================================================
	say("\n-- reduced motion --")
	local label2 = Instance.new("TextLabel")
	label2.Parent = layer
	local t2 = RarityFX.text(label2, nil)
	local e2 = RarityFX.edge(card, 6, 3)
	RarityFX.setActive(t2, true)
	RarityFX.setActive(e2, true)
	RarityFX.still = function()
		return true
	end
	RarityFX.setText(t2, "Divine", Color3.new(1, 1, 1))
	RarityFX.setEdge(e2, "Divine", true)
	check(t2.gradient.Enabled and t2.gradient.Rotation == 90 and not t2.animated and not RarityFX.isRunning(t2),
		"the word: its colours as a still two-tone, nothing running")
	check(not e2.frame.Visible and not RarityFX.isRunning(e2), "the edge: no light (the card keeps the colour)")
	-- Motion switched off while something runs: one step puts it all still.
	RarityFX.still = function()
		return false
	end
	RarityFX.setText(t2, "Divine", Color3.new(1, 1, 1))
	RarityFX.setEdge(e2, "Divine", true)
	check(RarityFX.isRunning(t2) and RarityFX.isRunning(e2), "with motion back, both run")
	RarityFX.still = function()
		return true
	end
	RarityFX.step(1010)
	check(not RarityFX.isRunning(t2) and not RarityFX.isRunning(e2) and t2.gradient.Rotation == 90,
		"turned off mid-run: the next step stills everything")
	RarityFX.still = function()
		return false
	end

	--==========================================================================
	-- 6. A BAG TILE AND A STRIP SLOT
	--==========================================================================
	say("\n-- a tile and a slot --")
	local tile = InventoryTile.build(layer, HOT, 5)
	local function tilePaint(extra)
		local p = { name = "Drizzlet", variant = "Mythic", variantColour = Color3.new(1, 0, 0), favourite = false,
			held = false, restoring = false, rarity = "Mythic", variantIsRarity = true }
		for k, v in pairs(extra or {}) do
			p[k] = v
		end
		-- A nil in a table literal is no key at all: say "no rarity" by name.
		if p.noRarity then
			p.rarity = nil
		end
		InventoryTile.paint(tile, HOT, p)
	end
	tilePaint()
	InventoryTile.animate(tile, true)
	check(tile.plate.ApplyStrokeMode == Enum.ApplyStrokeMode.Border and tile.plate.Color == FX.Mythic.Edge
			and tile.fxEdge.frame.Visible and RarityFX.isRunning(tile.fxEdge) and RarityFX.isRunning(tile.fxText)
			and not tile.marker.Visible and tile.name.TextColor3 == GameConfig.BagLook.Cream,
		"a Mythic tile: crimson edge, its light and its word running, a cream name, no in-hand mark")
	tilePaint({ held = true })
	check(tile.marker.Visible and tile.ringTint.Enabled and not tile.fxEdge.frame.Visible
			and tile.plate.Color == Color3.new(1, 1, 1),
		"in hand: the keyline and the amber diamond; the rarity light gives way")
	tilePaint({ restoring = true })
	check(not tile.fxEdge.frame.Visible and not tile.fxText.gradient.Enabled and tile.variant.Text ~= "Mythic",
		"restoring: no light, and the line says so, plainly")
	tilePaint({ variant = "Mega", variantIsRarity = false })
	check(not tile.fxText.gradient.Enabled and tile.fxEdge.frame.Visible,
		"a sized Mythic: the size word stays plain, the edge still carries the rarity")
	tilePaint({ noRarity = true, variant = "Big", variantIsRarity = false })
	check(not tile.fxEdge.frame.Visible and tile.plate.Color == HOT.Edge and not RarityFX.isRunning(tile.fxEdge),
		"an ordinary pod's tile: the plain edge and nothing moving")
	InventoryTile.animate(tile, false)
	tilePaint()
	check(not RarityFX.isRunning(tile.fxEdge) and not RarityFX.isRunning(tile.fxText),
		"switched off (the Bag shut, scrolled away): drawn, but nothing runs")

	local slot = HotbarCard.build(layer, 7, HOT, 4)
	RarityFX.setActive(slot.fxEdge, true)
	local function slotPaint(extra)
		local p = { empty = false, held = false, number = "7", name = "Snarlbloom", rarity = "Secret" }
		for k, v in pairs(extra or {}) do
			p[k] = v
		end
		if p.noRarity then
			p.rarity = nil
		end
		HotbarCard.paint(slot, HOT, p)
	end
	slotPaint()
	check(slot.stroke.Color == FX.Secret.Edge and slot.fxEdge.frame.Visible and RarityFX.isRunning(slot.fxEdge)
			and not slot.marker.Visible,
		"a Secret on the strip: a silver edge with its light")
	for _, state in ipairs({ "held", "target", "pending", "restoring" }) do
		slotPaint({ [state] = true })
		check(not slot.fxEdge.frame.Visible and not RarityFX.isRunning(slot.fxEdge),
			state .. " outranks the rarity light")
	end
	slotPaint({ held = true })
	check(slot.marker.Visible and slot.stroke.Color == Color3.new(1, 1, 1), "in hand: the diamond on the slot too")
	slotPaint({ target = true })
	check(slot.stroke.Color == Color3.new(1, 1, 1) and slot.stroke.Transparency == 0,
		"assign mode's bright edge is unchanged by a rarity")
	slotPaint({ pending = true })
	check(slot.stroke.Color == HOT.LitTop, "a pending equip's amber is unchanged by a rarity")
	slotPaint()
	HotbarCard.flash(slot, HOT.FlashArrived, HOT)
	check(not slot.fxEdge.frame.Visible and slot.stroke.Color == HOT.FlashArrived, "a flash puts the light out")
	slot.flashUntil = 0
	slotPaint({ empty = true })
	check(not slot.fxEdge.frame.Visible and math.abs(slot.stroke.Transparency - HOT.EmptyEdgeTransparency) < 1e-4,
		"an empty slot stays faint and still, whatever was there")
	slotPaint({ noRarity = true })
	check(slot.stroke.Color == HOT.Edge and not slot.fxEdge.frame.Visible, "no rarity: the plain edge")

	--==========================================================================
	-- 7. THE OTHER FIVE, STILL (2026-10-10)
	--==========================================================================
	say("\n-- the other five, still --")
	local EDGE = GameConfig.RarityEdge
	local five = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
	local named = true
	for _, id in ipairs(five) do
		named = named and typeof(EDGE.Colours[id]) == "Color3" and RarityFX.stillEdge(id) == EDGE.Colours[id]
			and RarityFX.edgeColour(id) == nil
	end
	for _, id in ipairs({ "Mythic", "Divine", "Secret" }) do
		named = named and EDGE.Colours[id] == nil and RarityFX.stillEdge(id) == nil
	end
	check(named and RarityFX.stillEdge(nil) == nil and RarityFX.stillEdge("Mythical") == nil,
		"a still edge colour for Common to Legendary, by the canonical ids; none for the three rarest or anything else")
	-- Legible: a Bag tile is drawn at 85% on a phone (UIKit.phoneMenuScale), the
	-- strip never smaller; every colour clear of the dark slate it stands on.
	local function lum(c)
		return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
	end
	local brightEnough = true
	for _, id in ipairs(five) do
		brightEnough = brightEnough and lum(EDGE.Colours[id]) > 0.45
	end
	check(EDGE.Ring * GameConfig.MenuSize.PhoneScale >= 1.5 and EDGE.Strip >= 1.5 and brightEnough,
		"legible: the ring 1.5 px or more drawn at a phone's 85%, the strip's edge 1.5 px, every colour light on dark slate",
		string.format("ring %.2f drawn, strip %g", EDGE.Ring * GameConfig.MenuSize.PhoneScale, EDGE.Strip))

	-- What may wear one: a GROWN plant only, by its FORM rarity.
	local faces = {}
	local wrong = {}
	for _, list in ipairs({ SeedData.Species or {}, SeedData.SecretSpecies or {}, SeedData.RainSpecies or {} }) do
		for _, s in ipairs(list) do
			local plant = InventoryModel.face(item("plant", s.Id, 1))
			local want = EDGE.Colours[s.Rarity]
			if plant.edge ~= want then
				table.insert(wrong, s.Id .. " plant " .. tostring(s.Rarity))
			end
			faces[s.Rarity] = true
			local pod = InventoryModel.face(item("pod", s.Id, 3, { hatched = false }))
			if pod.edge ~= nil then
				table.insert(wrong, s.Id .. " pod")
			end
			local rolling = InventoryModel.face(item("pod", s.Id, 3, { hatched = true, sealed = true }))
			if rolling.edge ~= nil then
				table.insert(wrong, s.Id .. " in its roll")
			end
		end
	end
	local weaponFace = InventoryModel.face(item("weapon", nil, 1, { weaponId = weaponId }))
	check(#wrong == 0 and faces.Common and faces.Legendary and weaponFace.edge == nil,
		"every species: grown, its form rarity's still edge (none for the three rarest); never a pod, a plant in its "
			.. "roll or equipment", table.concat(wrong, ", "))

	-- A Bag tile: the band inside the keyline, which stays.
	local tile2 = InventoryTile.build(layer, HOT, 5)
	local function paint2(extra)
		local p = { name = "Toadcap", variant = "Big", variantColour = Color3.new(1, 1, 1), favourite = false,
			held = false, restoring = false, rarity = "Rare", variantIsRarity = false, edge = EDGE.Colours.Rare,
			studs = GameConfig.BagLook.StudsByRarity.Rare }
		for k, v in pairs(extra or {}) do
			p[k] = v
		end
		if p.noEdge then
			p.edge = nil
		end
		InventoryTile.paint(tile2, HOT, p)
	end
	paint2()
	local ringStroke = tile2.ring:FindFirstChildOfClass("UIStroke")
	check(tile2.ring.Visible and ringStroke and ringStroke.Color == EDGE.Colours.Rare
			and ringStroke.Thickness == EDGE.Ring and tile2.ring.Size == UDim2.new(1, -EDGE.Ring * 2, 1, -EDGE.Ring * 2)
			and ringStroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border and tile2.plate.Color ~= EDGE.Colours.Rare
			and not tile2.fxEdge.frame.Visible,
		"a grown Rare's tile: a sky band just inside its edge, the tile's own keyline kept round it, no light")
	paint2({ held = true })
	check(not tile2.ring.Visible and tile2.marker.Visible, "in hand: the selection's look outranks the band")
	paint2({ restoring = true })
	check(tile2.ring.Visible, "restoring: the band stays (the colour alone)")
	paint2({ noEdge = true, rarity = "Rare", variant = "Big" })
	check(not tile2.ring.Visible, "a pod (no edge handed on): no band")
	paint2({ rarity = "Mythic", edge = nil, noEdge = true })
	check(not tile2.ring.Visible and tile2.plate.Color == FX.Mythic.Edge,
		"a Mythic: RarityFX's own edge, no band")

	-- A strip slot: its own edge, the quietest state but plain.
	local slot2 = HotbarCard.build(layer, 8, HOT, 4)
	local function slot2Paint(extra)
		local p = { empty = false, held = false, number = "8", name = "Bellchime", rarity = "Epic",
			edge = EDGE.Colours.Epic }
		for k, v in pairs(extra or {}) do
			p[k] = v
		end
		if p.noEdge then
			p.edge = nil
		end
		if p.noRarity then
			p.rarity = nil
		end
		HotbarCard.paint(slot2, HOT, p)
	end
	slot2Paint()
	check(slot2.stroke.Color == EDGE.Colours.Epic and slot2.stroke.Thickness == EDGE.Strip
			and slot2.stroke.Transparency <= 0.05 + 1e-6 and not slot2.fxEdge.frame.Visible,
		"a grown Epic on the strip: its violet on the slot's edge, Strip px, no light")
	slot2Paint({ held = true })
	check(slot2.stroke.Color == Color3.new(1, 1, 1) and slot2.stroke.Thickness == HOT.LitThickness,
		"in hand outranks it")
	slot2Paint({ target = true })
	check(slot2.stroke.Color == Color3.new(1, 1, 1), "assign mode's target outranks it")
	slot2Paint({ pending = true })
	check(slot2.stroke.Color == HOT.LitTop and slot2.stroke.Thickness == HOT.CardStroke,
		"a pending equip's amber outranks it")
	slot2Paint({ restoring = true })
	check(slot2.stroke.Color == EDGE.Colours.Epic, "restoring keeps it")
	slot2Paint()
	HotbarCard.flash(slot2, HOT.FlashArrived, HOT)
	check(slot2.stroke.Color == HOT.FlashArrived, "a flash outranks it")
	slot2.flashUntil = 0
	slot2Paint({ empty = true })
	check(slot2.stroke.Color == HOT.Edge and math.abs(slot2.stroke.Transparency - HOT.EmptyEdgeTransparency) < 1e-4,
		"an empty slot stays faint, whatever was there")
	slot2Paint({ noEdge = true, noRarity = true })
	check(slot2.stroke.Color == HOT.Edge and slot2.stroke.Thickness == HOT.CardStroke, "no edge: the plain one")
	slot2Paint({ rarity = "Divine", noEdge = true })
	check(slot2.stroke.Color == FX.Divine.Edge and slot2.stroke.Thickness == HOT.CardStroke,
		"a Divine: RarityFX's own edge, as before")

	-- The wiring: only a grown plant's face is handed its edge, on the strip and
	-- in the Bag; the Almanac's card wears it only once grown.
	local Client = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	local function src(name)
		local s = Client:FindFirstChild(name)
		return if s then s.Source else ""
	end
	local loadout, index = src("LoadoutUI"), src("IndexUI")
	check(string.find(loadout, "edge = if item and item.kind == \"plant\" and face then face.edge else nil", 1, true)
			and string.find(loadout, "edge = if group.category == \"plants\" then face.edge else nil", 1, true),
		"LoadoutUI hands the edge on for a grown plant only, on the strip and in the Bag")
	check(string.find(index, "local ring = RarityFX.ring(face, 8, Z + 4, (GameConfig.RarityEdge :: any).Ring)", 1, true)
			and string.find(index,
				"RarityFX.setRing(c.ring, if known and not rare then RarityFX.stillEdge(face.rarity) else nil)", 1, true),
		"the Almanac: a grown card wears its FORM rarity's band inside its keyline; a card not yet grown stays plain")
end)

RarityFX.still = realStill
layer:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nRarityFXSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
