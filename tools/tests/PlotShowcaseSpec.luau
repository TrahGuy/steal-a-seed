--!nocheck
--==============================================================================
-- Steal a Seed :: PlotShowcaseSpec (2026-10-05, the owner's TOP CREATURES board)
--
-- The board beside every plot's upgrade board, in Edit:
--
--   1. WHICH TWO: grown creatures only (a pod and a sprout never), the highest
--      SeedData.IncomePerSecond first, equal incomes in EQUIP BEST's order
--      (GardenPlan.before: the lower item id, an id before none, then the lower
--      placement id) -- the very order GardenPlan.best keeps; fewer than two.
--   2. WHAT THE SERVER PUBLISHES: each slot's species id, tier and placement
--      id as plain attributes on the board; a shorter list clears the rest; an
--      unchanged one writes nothing; a client reads it back and skips junk.
--   3. THE SERVICE ON STAND-INS: a plot of stand-in planted models and its
--      board -- PlotShowcaseService ranks what stands in THAT plot, and a
--      pick-up, a better planting and a hatch are each one new answer.
--   4. THE WORDS ARE PlantLabel.content: rarity, name, size and rate on every
--      card, at the owner's rate (GardenBoost x the rain) -- an ordinary plant,
--      TITAN and COLOSSAL in the wheel's lettering, a Secret and an unsized
--      event form with no size; RarityFX on Mythic / Divine / Secret only and
--      running only while near; the rarity's studded colour, a Common plain.
--   5. THE STATES: two, one and a quiet EMPTY slot, none and NO CREATURES YET,
--      hidden; the pictures built near and FREED far; the header, the canvas,
--      LightInfluence 0; the face ADORNED to the plank from its holder (the
--      PlayerGui), never under the Workspace, where no ViewportFrame draws;
--      every line at least the upgrade board's smallest and every species'
--      name fitting its card.
--   6. THE WIRING, read off the source: no loop, no remote, the tag's signals
--      and one delayed publish; MapService builds and tags the board; the
--      client draws only from attributes, hides a free or unknown garden and
--      frees its pictures with distance.
--
-- Not here, seen in Play instead: a real garden publishing, streaming, the
-- capture by day and at night. Placement: PlotShowcasePlacementSpec.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local GardenPlan = require(Shared:WaitForChild("GardenPlan"))
local PlantLabel = require(Shared:WaitForChild("PlantLabel"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local PlotShowcase = require(Shared:WaitForChild("PlotShowcase"))
local PlotShowcaseView = require(Shared:WaitForChild("PlotShowcaseView"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PlotShowcaseService = require(Server:WaitForChild("PlotShowcaseService"))

local SC = GameConfig.Plot.Showcase
local A = SC.Attributes
local BAG = GameConfig.BagLook
local FACTOR = GameConfig.Weather.Attributes.Factor
local GROWN, SPROUT, POD = 3, 2, 1

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
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
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
local function keysOf(rows)
	local t = {}
	for _, r in ipairs(rows) do
		table.insert(t, tostring(r.placementId))
	end
	return table.concat(t, ",")
end
local function row(species, tier, placementId, item)
	return PlotShowcase.row(species, tier, GROWN, placementId, item)
end

local fixture = Instance.new("Folder")
fixture.Name = "PlotShowcaseSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace
local rainWas = Workspace:GetAttribute(FACTOR)

-- A stand-in plot with its Plants folder, and its board: PlotIds from 9901, no
-- real plot's.
local SPEC_ID = 9901
local function standInPlot(id)
	local plot = Instance.new("Model")
	plot.Name = "SpecShowcasePlot" .. id
	plot:SetAttribute(GameConfig.Attributes.PlotId, id)
	local plants = Instance.new("Folder")
	plants.Name = GameConfig.Plot.PlantsFolderName
	plants.Parent = plot
	plot.Parent = fixture
	CollectionService:AddTag(plot, GameConfig.Tags.Plot)
	local board = Instance.new("Model")
	board.Name = "SpecShowcaseBoard" .. id
	board:SetAttribute(GameConfig.Attributes.PlotId, id)
	board.Parent = fixture
	CollectionService:AddTag(board, GameConfig.Tags.PlotShowcase)
	return plot, plants, board
end
local function plant(plants, species, tier, stage, placementId, item)
	local m = Instance.new("Model")
	m.Name = "SpecPlanted" .. placementId
	m:SetAttribute("SpeciesId", species)
	m:SetAttribute("Tier", tier)
	m:SetAttribute("Stage", stage)
	m:SetAttribute("PlacementId", placementId)
	m:SetAttribute(GameConfig.Attributes.ItemId, item)
	m.Parent = plants
	CollectionService:AddTag(m, GameConfig.Tags.Planted)
	return m
end

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. which two --")
	--==========================================================================
	local r = row("toadcap", 3, 7, "12")
	check(r and r.species == "toadcap" and r.tier == 3 and r.placementId == 7 and r.item == "12"
			and r.income == SeedData.IncomePerSecond(SeedData.Get("toadcap"), 3),
		"a grown creature is a row: species, tier, placement id, item id and the faucet's own income")
	check(PlotShowcase.row("toadcap", 3, POD, 1, "1") == nil and PlotShowcase.row("toadcap", 3, SPROUT, 1, "1") == nil,
		"a pod and a sprout still growing are never on the board")
	check(PlotShowcase.row("not_a_species", 3, GROWN, 1, "1") == nil and PlotShowcase.row("toadcap", "x", GROWN, 1, "1")
			== nil and PlotShowcase.row("toadcap", 3, GROWN, nil, "1") == nil and PlotShowcase.row(nil, 3, GROWN, 1, "1") == nil,
		"nor is an unknown species, a junk tier or a missing placement id")
	check(row("toadcap", 3, 1, nil).item == nil and row("toadcap", 3, 1, "").item == nil,
		"a legacy planting with no item id reads as none")

	local big = row("toadcap", 7, 1, "5")
	local mid = row("toadcap", 5, 2, "6")
	local small = row("nubkin", 1, 3, "7")
	local top = PlotShowcase.top({ small, big, mid })
	check(#top == 2 and top[1] == big and top[2] == mid,
		"the highest income first: a Colossal Toadcap, then a Giant one; the Nubkin is third and off the board",
		keysOf(top))
	local a = row("toadcap", 4, 9, "20")
	local b = row("toadcap", 4, 4, "31")
	local c = row("toadcap", 4, 2, "8")
	top = PlotShowcase.top({ a, b, c })
	check(#top == 2 and top[1] == c and top[2] == a, "equal incomes: the lower item id first (8, then 20)",
		keysOf(top))
	local legacy1 = row("toadcap", 4, 6, nil)
	local legacy2 = row("toadcap", 4, 3, nil)
	local withId = row("toadcap", 4, 8, "40")
	top = PlotShowcase.top({ legacy1, legacy2, withId })
	check(#top == 2 and top[1] == withId and top[2] == legacy2,
		"an item id before none, then the lower placement id", keysOf(top))
	-- The very order EQUIP BEST keeps, over a mixed garden.
	local garden = { a, b, c, legacy1, legacy2, withId, big, mid, small }
	local cands = {}
	for _, x in ipairs(garden) do
		table.insert(cands, { key = "p:" .. x.placementId, income = x.income, planted = true, item = x.item,
			placementId = x.placementId })
	end
	local best = GardenPlan.best(cands, 2, 0)
	top = PlotShowcase.top(garden)
	check(#top == 2 and #best.keep == 2 and best.keep[1].key == "p:" .. top[1].placementId
			and best.keep[2].key == "p:" .. top[2].placementId,
		"the board's two are the two EQUIP BEST would keep in a two-slot plot", keysOf(top))
	check(#PlotShowcase.top({ small }) == 1 and #PlotShowcase.top({}) == 0, "fewer than two: one, or none")
	check(#PlotShowcase.top({ big, big }) == 1, "the same placement twice is one creature")
	local secret = row("snarlbloom", 1, 11, "50")
	top = PlotShowcase.top({ big, secret })
	check(top[1] == secret and secret.income == SeedData.Get("snarlbloom").FixedIncome,
		"a Secret ranks by its own fixed rate (SeedData.IncomePerSecond), the faucet's number", secret.income)

	--==========================================================================
	say("\n-- 2. what the server publishes --")
	--==========================================================================
	local board = Instance.new("Model")
	board.Parent = fixture
	check(#PlotShowcase.attributeNames() == SC.Slots * 3, "three plain attributes a slot: species, tier, placement id")
	check(PlotShowcase.publish(board, { big, mid }) == true and board:GetAttribute(A.Species[1]) == "toadcap"
			and board:GetAttribute(A.Tier[1]) == 7 and board:GetAttribute(A.Placement[1]) == 1
			and board:GetAttribute(A.Species[2]) == "toadcap" and board:GetAttribute(A.Tier[2]) == 5
			and board:GetAttribute(A.Placement[2]) == 2,
		"two slots written: Top1 the Colossal (placement 1), Top2 the Giant (placement 2)")
	check(PlotShowcase.publish(board, { big, mid }) == false, "the same two again write nothing")
	PlotShowcase.publish(board, { mid })
	check(board:GetAttribute(A.Species[1]) == "toadcap" and board:GetAttribute(A.Tier[1]) == 5
			and board:GetAttribute(A.Species[2]) == nil and board:GetAttribute(A.Tier[2]) == nil
			and board:GetAttribute(A.Placement[2]) == nil,
		"one creature: slot 1 moves up, slot 2 is cleared")
	PlotShowcase.publish(board, { big, secret })
	local read = PlotShowcase.read(board)
	check(#read == 2 and read[1].species == "toadcap" and read[1].tier == 7 and read[1].placementId == 1
			and read[2].species == "snarlbloom" and read[2].placementId == 11,
		"a client reads the two back, in order")
	board:SetAttribute(A.Species[1], "not_a_species")
	board:SetAttribute(A.Tier[2], "junk")
	check(#PlotShowcase.read(board) == 0, "an unknown species or a junk tier is no slot, never a wrong one")
	PlotShowcase.publish(board, {})
	check(#PlotShowcase.read(board) == 0 and board:GetAttribute(A.Species[1]) == nil, "none: every slot cleared")

	--==========================================================================
	say("\n-- 3. the service, on stand-ins --")
	--==========================================================================
	local plot, plants, spBoard = standInPlot(SPEC_ID)
	local m1 = plant(plants, "toadcap", 5, GROWN, 101, "1")
	local m2 = plant(plants, "nubkin", 2, GROWN, 102, "2")
	plant(plants, "toadcap", 7, POD, 103, "3")
	plant(plants, "suncrown", 7, SPROUT, 104, "4")
	-- Somebody else's garden must not count.
	local otherPlot, otherPlants, otherBoard = standInPlot(SPEC_ID + 1)
	plant(otherPlants, "snarlbloom", 1, GROWN, 201, "9")
	check(PlotShowcaseService.PlotOf(m1) == plot and PlotShowcaseService.BoardFor(plot) == spBoard,
		"a planted model's plot is the tagged plot it stands in; its board the one with the same PlotId")
	local rows = PlotShowcaseService.Rows(plot)
	check(#rows == 2, "the plot's rows: its two GROWN creatures -- not its pod or its sprout, not the next plot's", #rows)
	PlotShowcaseService.Publish(plot)
	local shown = PlotShowcase.read(spBoard)
	check(#shown == 2 and shown[1].placementId == 101 and shown[2].placementId == 102,
		"published: the Giant Toadcap, then the Nubkin")
	-- A better creature planted.
	local m3 = plant(plants, "suncrown", 7, GROWN, 105, "5")
	PlotShowcaseService.Publish(plot)
	shown = PlotShowcase.read(spBoard)
	check(#shown == 2 and shown[1].placementId == 105 and shown[2].placementId == 101,
		"a better creature planted: it leads, and the Nubkin is off the board")
	-- Picked up: the Planted tag comes off before the model goes.
	CollectionService:RemoveTag(m3, GameConfig.Tags.Planted)
	PlotShowcaseService.Publish(plot)
	shown = PlotShowcase.read(spBoard)
	check(#shown == 2 and shown[1].placementId == 101 and shown[2].placementId == 102,
		"picked up: the next two move up")
	m2:Destroy()
	m1:Destroy()
	PlotShowcaseService.Publish(plot)
	check(#PlotShowcase.read(spBoard) == 0, "nothing grown left (a pod and a sprout only): no slots")
	check(PlotShowcaseService.Publish(plot) == false, "and publishing again changes nothing")
	PlotShowcaseService.Publish(otherPlot)
	local theirs = PlotShowcase.read(otherBoard)
	check(#theirs == 1 and theirs[1].placementId == 201 and #PlotShowcase.read(spBoard) == 0,
		"the next plot's board shows its own Secret, and this one stays empty")
	plot:Destroy()
	otherPlot:Destroy()
	spBoard:Destroy()
	otherBoard:Destroy()

	--==========================================================================
	say("\n-- 4. the words are PlantLabel.content --")
	--==========================================================================
	local plank = Instance.new("Part")
	plank.Name = "Board"
	plank.Anchored = true
	plank.Size = SC.BoardSize
	plank.CFrame = CFrame.new(0, 400, 0)
	plank.Parent = fixture
	-- The face's holder: on a client the PlayerGui. Here a folder beside the
	-- plank, never the plank itself.
	local faces = Instance.new("Folder")
	faces.Name = "SpecFaces"
	faces.Parent = fixture
	local view = PlotShowcaseView.new(plank, faces)
	local rateHost = Instance.new("Folder")
	rateHost.Parent = fixture
	rateHost:SetAttribute(GameConfig.Attributes.GardenBoost, 2)
	Workspace:SetAttribute(FACTOR, 1.25)
	local multiplier = GameConfig.gardenIncomeMultiplier(rateHost)
	check(math.abs(multiplier - 2.5) < 1e-9, "the owner's rate: the plot's GardenBoost x2 and the rain x1.25", multiplier)

	local function slot(species, tier, id)
		return { species = species, tier = tier, placementId = id }
	end
	local cases = {
		{ "an ordinary plant", slot("toadcap", 3, 1), slot("nubkin", 1, 2) },
		{ "TITAN and COLOSSAL", slot("toadcap", 6, 3), slot("toadcap", 7, 4) },
		{ "a Secret and a Mythic event form (no size)", slot("snarlbloom", 1, 5), slot("puddlepod", 1, 6) },
		{ "a Legendary and a Divine", slot("suncrown", 4, 7), slot("tempestoak", 1, 8) },
		{ "a Mythic", slot("gloomlotus", 2, 9), slot("nubkin", 3, 10) },
	}
	for _, case in ipairs(cases) do
		local slots = { case[2], case[3] }
		PlotShowcaseView.paint(view, slots, multiplier)
		local bad = {}
		for i, s in ipairs(slots) do
			local want = PlantLabel.content(s.species, s.tier, multiplier)
			local card = view.cards[i]
			local style = RarityFX.style(want.rarity)
			local gradient = card.rarity:FindFirstChild("RarityLight")
			local studKey = BAG.StudsByRarity[want.rarity]
			local prestige = card.size:FindFirstChild("Prestige")
			local function bad_(what)
				table.insert(bad, string.format("%s #%d %s", s.species, i, what))
			end
			if card.rarity.Text ~= want.rarityText then
				bad_("rarity " .. card.rarity.Text)
			end
			if style then
				if not (gradient and gradient.Enabled) then
					bad_("no RarityFX light on " .. want.rarity)
				end
			elseif card.rarity.TextColor3 ~= want.rarityColour or (gradient and gradient.Enabled) then
				bad_("rarity colour")
			end
			if card.name.Text ~= want.name then
				bad_("name " .. card.name.Text)
			end
			if card.income.Text ~= want.income then
				bad_("income " .. card.income.Text)
			end
			if want.size == nil then
				if card.size.Visible then
					bad_("a size where there is none")
				end
			else
				if not card.size.Visible or card.size.Text ~= want.size then
					bad_("size " .. card.size.Text)
				end
				if want.sizeStyle then
					if not prestige then
						bad_("no wheel lettering on " .. want.size)
					end
				elseif prestige or card.size.TextColor3 ~= want.sizeColour then
					bad_("size colour")
				end
			end
			if studKey then
				if not (card.studs.image.Visible and card.studs.image.Image == BAG.Studs[studKey].image) then
					bad_("not on its " .. studKey .. " studs")
				end
				if not card.words.Visible then
					bad_("no ink backing on a studded card")
				end
			elseif card.studs.image.Visible or card.words.Visible then
				bad_("a Common not on the plain card")
			end
		end
		check(#bad == 0, case[1] .. ": rarity, name, size and rate as PlantLabel.content says, at the owner's rate; "
			.. "its studded colour", table.concat(bad, "; "))
	end
	PlotShowcaseView.paint(view, { slot("gloomlotus", 2, 1), slot("toadcap", 3, 2) }, 1)
	PlotShowcaseView.setActive(view, true)
	local mythic, rare = view.cards[1], view.cards[2]
	check(RarityFX.isRunning(mythic.rarityFX) == not RarityFX.still() and RarityFX.isRunning(mythic.edgeFX)
			== not RarityFX.still() and not RarityFX.isRunning(rare.rarityFX),
		"near: a Mythic's light runs (still under reduced motion); a Rare has none")
	PlotShowcaseView.setActive(view, false)
	check(not RarityFX.isRunning(mythic.rarityFX) and not RarityFX.isRunning(mythic.edgeFX),
		"far: the light stops")
	Workspace:SetAttribute(FACTOR, rainWas)

	--==========================================================================
	say("\n-- 5. the states --")
	--==========================================================================
	local gui = view.gui
	check(gui:IsA("SurfaceGui") and gui.Face == Enum.NormalId.Front and gui.LightInfluence == 0
			and gui.AlwaysOnTop == false and gui.Active == false and gui.MaxDistance == SC.MaxDistance
			and gui.CanvasSize == PlotShowcaseView.Canvas
			and PlotShowcaseView.Canvas == Vector2.new(SC.BoardSize.X * SC.PixelsPerStud, SC.BoardSize.Y * SC.PixelsPerStud)
			and gui.ZIndexBehavior == Enum.ZIndexBehavior.Global,
		"the face: the plank's front, never lit by the world (night does not black it out), never on top or pressable, "
			.. "the plank's own size at PixelsPerStud")
	check(gui.Adornee == plank and gui.Parent == faces and not gui:IsDescendantOf(plank) and gui.ResetOnSpawn == false,
		"ADORNED to the plank and held by the holder it is given (the PlayerGui), never under the plank: a SurfaceGui "
			.. "under the Workspace draws no ViewportFrame (the owner's published board: cards, no creature); kept "
			.. "through a respawn", tostring(gui.Parent))
	local studs = view.header:FindFirstChild("Studs")
	local titleLine = view.title:FindFirstChildOfClass("UIStroke")
	check(view.title.Text == SC.Title and view.title.Font == Enum.Font.LuckiestGuy and view.title.TextColor3 == BAG.Title
			and titleLine and titleLine.Color == BAG.Ink and titleLine.Thickness >= 3 and studs
			and studs:GetAttribute("Face") == BAG.RimStud and studs:GetAttribute("Shade") == BAG.RimStudShade,
		"the header: the white studded rim and a white LuckiestGuy " .. SC.Title .. " with a heavy ink line")
	-- Readable: no line smaller than the upgrade board's own smallest.
	local signSmallest = 20 / (224 / (5.6 * GameConfig.Mill.Sign.Scale))
	local small = math.huge
	for _, px in pairs(PlotShowcaseView.TextSizes) do
		small = math.min(small, px)
	end
	small = math.min(small, PlotShowcaseView.NameMinSize)
	check(small / SC.PixelsPerStud >= signSmallest - 1e-6,
		string.format("every line at least the upgrade board's smallest: %.2f studs tall against its %.2f",
			small / SC.PixelsPerStud, signSmallest))
	local tooLong, longest, longestW, names = {}, "", 0, 0
	for _, list in ipairs({ SeedData.Species, SeedData.SecretSpecies, SeedData.RainSpecies }) do
		for _, species in ipairs(list) do
			-- The name the board prints: PlantLabel.content's.
			local word = PlantLabel.content(species.Id, SeedData.TierCount, 1).name
			local w = TextService:GetTextSize(word, PlotShowcaseView.NameMinSize, Enum.Font.FredokaOne,
				Vector2.new(4000, 200)).X
			names += 1
			if w > longestW then
				longest, longestW = word, w
			end
			if w > PlotShowcaseView.NameWidth then
				table.insert(tooLong, string.format("%s %d px", word, w))
			end
		end
	end
	check(#tooLong == 0 and names > 30,
		string.format("all %d species' names fit their card at %d px or more (the longest, %s, %d of %d px)", names,
			PlotShowcaseView.NameMinSize, longest, longestW, PlotShowcaseView.NameWidth), table.concat(tooLong, ", "))

	PlotShowcaseView.paint(view, { slot("toadcap", 3, 1), slot("suncrown", 4, 2) }, 1)
	check(not view.none.Visible and view.cards[1].holder.Visible and view.cards[2].holder.Visible
			and view.cards[1].filled and view.cards[2].filled and #view.contents == 2,
		"two creatures: two cards")
	PlotShowcaseView.paint(view, { slot("toadcap", 3, 1) }, 1)
	local quiet = view.cards[2]
	check(view.cards[1].filled and not quiet.filled and quiet.empty.Visible and quiet.empty.Text == SC.EmptySlot
			and not quiet.name.Visible and not quiet.rarity.Visible and not quiet.income.Visible
			and not quiet.studs.image.Visible and not quiet.words.Visible and quiet.face.BackgroundTransparency > 0,
		"one creature: it, and a quiet EMPTY slot beside it")
	PlotShowcaseView.paint(view, {}, 1)
	check(view.none.Visible and not view.cards[1].holder.Visible and not view.cards[2].holder.Visible
			and view.noneTitle.Text == SC.EmptyTitle and view.noneLine.Text == SC.EmptyLine,
		"none: one friendly card -- " .. SC.EmptyTitle .. " / " .. SC.EmptyLine)

	local function pictures()
		local n = 0
		for _, card in ipairs(view.cards) do
			local p = card.previewHost:FindFirstChild("Preview")
			local hero = p and p:FindFirstChildWhichIsA("ViewportFrame", true)
			if hero and #hero:GetChildren() > 0 then
				n += 1
			end
		end
		return n
	end
	PlotShowcaseView.paint(view, { slot("toadcap", 3, 1), slot("nubkin", 2, 2) }, 1)
	check(pictures() == 0, "far (the default): no pictures built")
	PlotShowcaseView.setPreviews(view, true)
	check(pictures() == 2, "near: each card's creature itself, in a ViewportFrame (ItemArt + UIKit.itemPreview)",
		pictures())
	PlotShowcaseView.paint(view, { slot("toadcap", 3, 1) }, 1)
	check(pictures() == 1 and view.cards[2].previewHost:FindFirstChild("Preview") == nil,
		"a quiet slot has no picture")
	PlotShowcaseView.setPreviews(view, false)
	check(pictures() == 0 and view.cards[1].previewHost:FindFirstChild("Preview") == nil,
		"far again: the pictures are FREED, ViewportFrame and model, not hidden")
	PlotShowcaseView.setPreviews(view, true)
	PlotShowcaseView.setShown(view, false)
	check(gui.Enabled == false and pictures() == 0 and not view.active, "hidden: the face off, no pictures, no light")
	PlotShowcaseView.setShown(view, true)
	PlotShowcaseView.destroy(view)
	check(gui.Parent == nil and faces:FindFirstChild(PlotShowcaseView.GuiName) == nil,
		"destroyed: the face is gone from its holder")

	--==========================================================================
	say("\n-- 6. the wiring --")
	--==========================================================================
	local service = sourceOf(Server, "PlotShowcaseService")
	check(service ~= "" and not has(service, "while true") and not has(service, "while running")
			and not has(service, "task.wait(") and not has(service, "Heartbeat") and not has(service, "RenderStepped")
			and not has(service, "Stepped") and not has(service, "OnServerEvent") and not has(service, "RemoteEvent"),
		"the service has no polling loop, no wait, no frame hook and no remote")
	check(has(service, "CollectionService:GetInstanceAddedSignal(TAG_PLANTED):Connect(arrive)")
			and has(service, "CollectionService:GetInstanceRemovedSignal(TAG_PLANTED):Connect(leave)")
			and has(service, "task.delay(SC.PublishDelaySeconds") and has(service, "PlotShowcase.publish(board, PlotShowcase.top(")
			and has(service, "{ \"Stage\", \"Tier\", \"SpeciesId\" }"),
		"it answers the Planted tag coming and going and a model's Stage / Tier / SpeciesId, one delayed publish a burst")
	local map = sourceOf(Server, "MapService")
	check(has(map, "PlotShowcase.build(\n\t\t\tGameConfig.plotShowcaseBase(cf, GameConfig.StartingPlotTier), plots)")
			and has(map, "showcase.ModelStreamingMode = Enum.ModelStreamingMode.Atomic")
			and has(map, "showcase:SetAttribute(GameConfig.Attributes.PlotId, id)")
			and has(map, "CollectionService:AddTag(showcase, GameConfig.Tags.PlotShowcase)"),
		"MapService builds every board in `plots` off the gate, Atomic, with its PlotId and tag")
	local ui = sourceOf(StarterPlayer, "PlotShowcaseUI")
	check(ui ~= "" and has(ui, "PlotShowcase.read(e.model), GameConfig.gardenIncomeMultiplier(e.plot)")
			and not has(ui, "FireServer") and not has(ui, "InvokeServer") and not has(ui, "Remotes"),
		"the client draws from the board's attributes at the plot's published rate, and sends nothing")
	check(has(ui, "type(owner) == \"number\" and owner > 0 and type(plot:GetAttribute(ATTR.GardenGrown)) == \"number\"")
			and has(ui, "LocalTransparencyModifier"),
		"a free plot, or a garden not yet known, hides the board: the plaque's own rule")
	local viewSrc = sourceOf(Shared, "PlotShowcaseView")
	check(has(ui, "local playerGui = player:WaitForChild(\"PlayerGui\")")
			and has(ui, "e.view = PlotShowcaseView.new(plank, playerGui)")
			and has(viewSrc, "gui.Adornee = board") and has(viewSrc, "gui.Parent = parent")
			and not has(viewSrc, "gui.Parent = board") and has(ui, "plank.AncestryChanged:Connect("),
		"every face is built in the PlayerGui and adorned to its plank, and goes when its plank leaves the world")
	check(has(ui, "if e.near then d <= SC.PreviewFarStuds else d <= SC.PreviewNearStuds")
			and has(ui, "since >= SC.CheckSeconds") and SC.PreviewFarStuds > SC.PreviewNearStuds
			and SC.PreviewFarStuds < SC.MaxDistance,
		string.format("pictures and light from %d studs, freed past %d (checked every %.2f s), the face to %d",
			SC.PreviewNearStuds, SC.PreviewFarStuds, SC.CheckSeconds, SC.MaxDistance))
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

Workspace:SetAttribute(FACTOR, rainWas)
fixture:Destroy()

say(string.format("\nPlotShowcaseSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
