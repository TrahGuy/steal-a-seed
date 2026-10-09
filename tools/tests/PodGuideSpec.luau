--!nocheck
--==============================================================================
-- Steal a Seed :: PodGuideSpec
--
-- The Pod Guide's numbers (2026-10-09; KB/POD-GUIDE-PLAN.md): what a nest's pod
-- hatches and what its size is worth, worked out from the data the real rolls
-- draw from. Edit mode, pure.
--
--   1. each biome's five plants and their chances, adding up to 100%; the
--      plan's table; a plant no nest stocks has none
--   2. each biome's seven sizes, adding up to 100%, the biome's bonus on Mega
--      and up; the sizes' worth against Tiny
--   3. both match the real rolls (SeedData.Roll, SeedData.RollTier) over
--      100,000 seeded draws a biome
--   4. the secret row follows GameConfig.Secret; the words: percentages,
--      times, a plant's income at every size
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local PodGuide = require(Shared:WaitForChild("PodGuide"))

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
local function near(a, b, eps)
	return math.abs(a - b) <= eps
end

local BIOMES = {}
for _, biome in ipairs(BiomeData.Biomes) do
	table.insert(BIOMES, biome.Id)
end

--==============================================================================
say("1. The plants")
--==============================================================================
local sumsOk, fiveOk, orderOk = true, true, true
local d1 = ""
for _, id in ipairs(BIOMES) do
	local rows = PodGuide.plants(id)
	local sum = 0
	for i, row in ipairs(rows) do
		sum += row.chance
		if row.species ~= SeedData.InBiome(id)[i] then
			orderOk = false
		end
	end
	if not near(sum, 1, 1e-12) then
		sumsOk = false
		d1 ..= string.format(" %s %.15f", id, sum)
	end
	if #rows ~= 5 then
		fiveOk = false
		d1 ..= string.format(" %s %d plants", id, #rows)
	end
end
check(sumsOk and fiveOk and orderOk, "every biome's five plants, in its nest's draw order, add up to 100%", d1)

-- The plan's table (KB/POD-GUIDE-PLAN.md), to the thousandth of a percent.
local PLAN = {
	nubkin = 43.029, petalpip = 43.029, spiretip = 11.188, toadcap = 2.367, bellchime = 0.387,
	dunebud = 44.414, paddlehop = 44.414, thornwhorl = 9.395, raincup = 1.537, suncrown = 0.239,
}
local planOk, d2 = true, ""
for id, pct in pairs(PLAN) do
	if not near(PodGuide.chanceOf(id) * 100, pct, 0.0006) then
		planOk = false
		d2 ..= string.format(" %s %.4f", id, PodGuide.chanceOf(id) * 100)
	end
end
for _, id in ipairs({ "tanglemire", "emberroot", "starbloom" }) do
	local rows = PodGuide.plants(id)
	local want = { 45.598, 45.598, 7.461, 1.161, 0.182 }
	local got = {}
	for _, row in ipairs(rows) do
		table.insert(got, row.chance * 100)
	end
	table.sort(got, function(a, b)
		return a > b
	end)
	for i, pct in ipairs(want) do
		if not near(got[i] or -1, pct, 0.0006) then
			planOk = false
			d2 ..= string.format(" %s #%d %.4f", id, i, got[i] or -1)
		end
	end
end
check(planOk, "the chances are the plan's: Greenhollow 43 / 43 / 11.2 / 2.37 / 0.387%, Dustbowl 44.4 / 44.4 / 9.4 / "
	.. "1.54 / 0.239%, the other three 45.6 / 45.6 / 7.46 / 1.16 / 0.182%", d2)
check(PodGuide.chanceOf(SeedData.SecretByBiome.greenhollow) == 0 and PodGuide.chanceOf("nothing") == 0,
	"a plant no nest stocks (a secret, an unknown id) has no chance")

--==============================================================================
say("\n2. The sizes")
--==============================================================================
local sizeSumOk, sizeRuleOk, worthOk = true, true, true
local d3 = ""
for _, id in ipairs(BIOMES) do
	local rows = PodGuide.sizes(id)
	local bonus = BiomeData.ById[id].RarityBonus
	local sum = 0
	for i, row in ipairs(rows) do
		sum += row.chance
		local t = SeedData.Tiers[i]
		-- Against Tiny, the bonus multiplies Mega and up only.
		local ratio = row.chance / rows[1].chance
		local want = (if i >= 4 then t.weight * bonus else t.weight) / SeedData.Tiers[1].weight
		if row.tier ~= i or row.name ~= t.name or not near(ratio, want, 1e-9) then
			sizeRuleOk = false
			d3 ..= string.format(" %s %s", id, t.name)
		end
		if row.worth ~= t.value / SeedData.Tiers[1].value then
			worthOk = false
		end
	end
	if not near(sum, 1, 1e-12) then
		sizeSumOk = false
		d3 ..= string.format(" %s sum %.15f", id, sum)
	end
end
check(sizeSumOk, "every biome's seven sizes add up to 100%", d3)
check(sizeRuleOk, "the biome's RarityBonus multiplies Mega and up, nothing below", d3)
local gh, sb = PodGuide.sizes("greenhollow"), PodGuide.sizes("starbloom")
check(near(gh[1].chance, 0.5325, 1e-12) and near(gh[7].chance, 0.0052, 1e-12) and near(sb[7].chance * 100, 1.759, 0.001)
		and near(sb[1].chance * 100, 20.019, 0.001),
	"Greenhollow's are the table's own (Tiny 53.25%, Colossal 0.52%); Starbloom's bonus of 9 lifts Colossal to 1.76%",
	string.format("Starbloom Tiny %.3f Colossal %.3f", sb[1].chance * 100, sb[7].chance * 100))
local worths = {}
for _, row in ipairs(gh) do
	table.insert(worths, PodGuide.times(row.worth))
end
check(worthOk and table.concat(worths, " ") == "x1 x7 x35 x132 x412 x1,300 x2,375",
	"a size's worth against Tiny is the sizes' value: x1 x7 x35 x132 x412 x1,300 x2,375", table.concat(worths, " "))

--==============================================================================
say("\n3. The real rolls, 100,000 seeded draws a biome")
--==============================================================================
local N = 100000
local plantsOk, sizesOk = true, true
local d4 = ""
for b, id in ipairs(BIOMES) do
	local rng = Random.new(20261009 + b)
	local seenPlant, seenSize = {}, {}
	local bonus = BiomeData.ById[id].RarityBonus
	for _ = 1, N do
		local sp = SeedData.Roll(id, rng)
		seenPlant[sp.Id] = (seenPlant[sp.Id] or 0) + 1
		local tier = SeedData.RollTier(rng, bonus)
		seenSize[tier] = (seenSize[tier] or 0) + 1
	end
	-- Four standard errors and a hair: a seeded run, so a pass stays a pass.
	local function within(p, count)
		local f = count / N
		return math.abs(f - p) <= 4 * math.sqrt(p * (1 - p) / N) + 1e-4
	end
	for _, row in ipairs(PodGuide.plants(id)) do
		if not within(row.chance, seenPlant[row.species.Id] or 0) then
			plantsOk = false
			d4 ..= string.format(" %s %s %.4f vs %.4f", id, row.species.Id, (seenPlant[row.species.Id] or 0) / N, row.chance)
		end
	end
	for _, row in ipairs(PodGuide.sizes(id)) do
		if not within(row.chance, seenSize[row.tier] or 0) then
			sizesOk = false
			d4 ..= string.format(" %s %s %.4f vs %.4f", id, row.name, (seenSize[row.tier] or 0) / N, row.chance)
		end
	end
end
check(plantsOk, "the plants' chances match SeedData.Roll's draws in every biome", d4)
check(sizesOk, "the sizes' chances match SeedData.RollTier's draws with each biome's bonus", d4)

--==============================================================================
say("\n4. The secret row and the words")
--==============================================================================
local secretOk = true
for _, id in ipairs(BIOMES) do
	local row = PodGuide.secret(id)
	local cfg = BiomeData.ById[id].Secret
	if GameConfig.Secret.Enabled then
		if (cfg ~= nil) ~= (row ~= nil) or (row and (row.chance ~= cfg.SpawnChance or row.speciesId ~= SeedData.SecretByBiome[id])) then
			secretOk = false
		end
	elseif row ~= nil then
		secretOk = false
	end
end
check(secretOk, "the secret row only while secrets are on (GameConfig.Secret.Enabled: " .. tostring(GameConfig.Secret.Enabled)
	.. "), with its biome's own chance")
local words = {
	PodGuide.percent(PodGuide.chanceOf("nubkin")), PodGuide.percent(PodGuide.chanceOf("spiretip")),
	PodGuide.percent(PodGuide.chanceOf("toadcap")), PodGuide.percent(PodGuide.chanceOf("bellchime")),
	PodGuide.percent(gh[7].chance), PodGuide.percent(sb[7].chance), PodGuide.percent(1), PodGuide.percent(0),
}
check(table.concat(words, " ") == "43% 11.2% 2.37% 0.387% 0.52% 1.76% 100% 0%",
	"a chance is written to three figures: 43% 11.2% 2.37% 0.387% 0.52% 1.76%", table.concat(words, " "))
local nub = table.concat(PodGuide.incomes("nubkin"), "/")
local bell = table.concat(PodGuide.incomes("bellchime"), "/")
local cos = table.concat(PodGuide.incomes("cosmospire"), "/")
check(nub == "4/28/140/530/1650/5200/9500" and bell == "8/56/280/1060/3300/10400/19000"
		and cos == "10/61/296/1115/3467/10922/19952",
	"a plant's income at every size is SeedData.IncomePerSecond's (Nubkin 4 to 9,500, Bellchime 8 to 19,000)",
	nub .. " | " .. bell .. " | " .. cos)

--==============================================================================
say("\n5. The stands")
--==============================================================================
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local PodGuideStand = require(Shared:WaitForChild("PodGuideStand"))
local PodGuideView = require(Shared:WaitForChild("PodGuideView"))
local CFG = GameConfig.PodGuide
local MAP = GameConfig.Map
local fixture = Instance.new("Folder")
fixture.Name = "ZZPodGuideSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace
local ok5, err5 = pcall(function()
	local placeOk, inertOk, podsOk, turnOk, quietOk, wordsOk = true, true, true, true, true, true
	local d5, d6 = "", ""
	for _, id in ipairs(BIOMES) do
		local biome = BiomeData.ById[id]
		local nearZ, farZ = BiomeData.SegmentBounds(biome)
		local frame = PodGuideStand.frame(id)
		local model = PodGuideStand.build(id, fixture)
		-- Inside its own arch, by the road, clear of the racing line and the walls; facing the road.
		local at = frame.Position
		local board = PodGuideStand.boardFrame(frame)
		local half = CFG.BoardSize.X / 2
		if not (math.abs(at.X) - CFG.TurntableRadius >= 24 and math.abs(board.Position.X) + CFG.BoardSize.Z <= 70
			and at.Z - half > farZ and at.Z + half < nearZ and math.abs(at.Y - MAP.GroundY) < 1e-6
			and frame.LookVector:Dot(Vector3.new(-math.sign(at.X), 0, 0)) > 0.999) then
			placeOk = false
			d5 ..= string.format(" %s %s", id, tostring(at))
		end
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and (not p.Anchored or p.CanCollide or p.CanQuery or p.CanTouch) then
				inertOk = false
				d5 ..= " " .. id .. ":" .. p.Name
			end
		end
		-- The carousel: the biome's five, the game's own pods, idled (PodShowcase), never loot; on the turntable at
		-- any angle; no words on any of them.
		local carousel = PodGuideStand.buildPods(id, frame, fixture)
		local top = at.Y + CFG.TurntableHeight
		local seen = {}
		for _, pod in ipairs(carousel.pods) do
			seen[pod:GetAttribute("SpeciesId")] = true
			if pod:GetAttribute(GameConfig.PodModels.Motion.ShowcaseAttribute) ~= true
				or CollectionService:HasTag(pod, GameConfig.Tags.SeedPod) or CollectionService:HasTag(pod, GameConfig.Tags.Planted)
				or not CollectionService:HasTag(pod, GameConfig.PodModels.Tag) then
				podsOk = false
				d6 ..= " " .. pod.Name .. " tags"
			end
			for _, d in ipairs(pod:GetDescendants()) do
				if d:IsA("LayerCollector") or d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
					wordsOk = false
					d6 ..= " " .. pod.Name .. " text"
				end
			end
		end
		for _, row in ipairs(PodGuide.plants(id)) do
			if not seen[row.species.Id] then
				podsOk = false
				d6 ..= " " .. id .. " missing " .. row.species.Id
			end
		end
		for _, angle in ipairs({ 0, 1.1, 2.5, 4.9 }) do
			PodGuideStand.turn(carousel, frame, angle)
			for _, pod in ipairs(carousel.pods) do
				local cf, size = pod:GetBoundingBox()
				-- The Shell (the pivot) stands over the pod's base.
				local pivot = pod:GetPivot().Position
				local flat = Vector3.new(pivot.X - at.X, 0, pivot.Z - at.Z)
				if math.abs(flat.Magnitude - CFG.Radius) > 0.05 or cf.Position.Y - size.Y / 2 < top - 0.05
					or flat.Magnitude + math.max(size.X, size.Z) / 2 > CFG.TurntableRadius + 1.2 then
					turnOk = false
					d6 ..= string.format(" %s %.1f r%.2f", pod.Name, angle, flat.Magnitude)
				end
			end
		end
		if #carousel.pods ~= 5 then
			podsOk = false
		end
		-- It really turns, on the real clock's angle too: three seconds of a 2026 server clock move every pod
		-- (the angle is in the hundreds of millions; a float's CFrame.Angles once held it still).
		local clockAngle = 1.79e9 / CFG.TurnSeconds * 2 * math.pi
		PodGuideStand.turn(carousel, frame, clockAngle)
		local was = carousel.pods[1]:GetPivot().Position
		PodGuideStand.turn(carousel, frame, clockAngle + 3 / CFG.TurnSeconds * 2 * math.pi)
		local moved = (carousel.pods[1]:GetPivot().Position - was).Magnitude
		local chord = 2 * CFG.Radius * math.sin(3 / CFG.TurnSeconds * math.pi)
		if math.abs(moved - chord) > 0.05 then
			turnOk = false
			d6 ..= string.format(" %s moved %.2f want %.2f", id, moved, chord)
		end
	end
	check(placeOk, "each stand is just inside its own arch, by the road, clear of the racing line and the walls, facing the road", d5)
	check(inertOk, "nothing on a stand collides, is queried or touched", d5)
	check(podsOk, "its carousel is the biome's five pods, built by the game's own builder: idled (PodShowcase), never loot", d6)
	check(turnOk, "the carousel turns them round on the turntable, each the same distance out at every angle", d6)
	check(wordsOk, "and no pod carries a word (2026-09-17: a pod carries no words at all)", d6)
	local creature = Shared:FindFirstChild("CreatureModel").Source
	check(string.find(creature, "A POD CARRIES NO WORDS AT ALL", 1, true) ~= nil
			and string.find(creature, "rule is the whole category: no species, no rarity, no tier, no name", 1, true) ~= nil,
		"the 2026-09-17 rule still stands in CreatureModel, word for word")

	--==========================================================================
	say("\n6. The board")
	--==========================================================================
	local plank = fixture:FindFirstChild("PodGuide_greenhollow"):FindFirstChild(PodGuideStand.BOARD)
	local faces = Instance.new("Folder")
	faces.Name = "Faces"
	faces.Parent = fixture
	local view = PodGuideView.new(plank, faces, "greenhollow")
	local function textOf(name)
		local found = view.gui:FindFirstChild(name, true)
		return found and found.Text
	end
	local rows = PodGuide.plants("greenhollow")
	local cardsOk, hiddenOk = #view.cards == #rows, true
	for i, card in ipairs(view.cards) do
		if card.species ~= rows[i].species or card.chance.Text ~= PodGuide.percent(rows[i].chance)
			or card.rarity.Text ~= string.upper(rows[i].species.Rarity) then
			cardsOk = false
		end
		if card.name.Text ~= "???" then
			hiddenOk = false
		end
	end
	local sizesOk = true
	for i, s in ipairs(PodGuide.sizes("greenhollow")) do
		if textOf("SizeChance" .. i) ~= PodGuide.percent(s.chance) or textOf("SizeWorth" .. i) ~= PodGuide.times(s.worth)
			or textOf("Size" .. i) ~= string.upper(s.name) then
			sizesOk = false
		end
	end
	check(view.gui.Adornee == plank and view.gui.Parent == faces and view.gui.CanvasSize == PodGuideView.Canvas
			and PodGuideView.Canvas == Vector2.new(math.floor(CFG.BoardSize.X * CFG.PixelsPerStud + 0.5),
				math.floor(CFG.BoardSize.Y * CFG.PixelsPerStud + 0.5))
			and view.title.Text == "GREENHOLLOW PODS" and cardsOk and sizesOk,
		"the board: GREENHOLLOW PODS, each plant with its rarity and its chance in draw order, the seven sizes' odds and worth",
		view.title.Text)
	check(hiddenOk, "a plant not yet grown is ??? on the board, as in the Almanac")
	PodGuideView.paint(view, { nubkin = true })
	local named = view.cards[1].species.Id == "nubkin" and view.cards[1].name.Text == "Nubkin"
		and view.cards[2].name.Text == "???"
	check(named, "a grown plant is named; the others stay ???", view.cards[1].name.Text .. " / " .. view.cards[2].name.Text)
	check(view.secret.Visible == (PodGuide.secret("greenhollow") ~= nil),
		"the secret line shows only while secrets are on")
	local function pictures()
		local n = 0
		for _, d in ipairs(view.gui:GetDescendants()) do
			if d:IsA("ViewportFrame") then
				n += 1
			end
		end
		return n
	end
	check(pictures() == 0, "far: no pictures at all")
	PodGuideView.setPreviews(view, true)
	local near = pictures()
	local tinted = view.cards[2].plantPreview ~= nil
		and view.cards[2].plantPreview.hero.ImageColor3 == GameConfig.Almanac.Silhouette
		and view.cards[1].plantPreview.hero.ImageColor3 == Color3.new(1, 1, 1)
	PodGuideView.setPreviews(view, false)
	check(near == 10 and tinted and pictures() == 0,
		"near: each card's pod and its plant (a silhouette until grown); far again: all ten FREED, not hidden",
		string.format("near %d, after %d", near, pictures()))
	local readable = true
	for _, size in pairs(PodGuideView.TextSizes) do
		if size / CFG.PixelsPerStud < 0.33 then
			readable = false
		end
	end
	check(readable, "every line on the board is at least a third of a stud tall")
	PodGuideView.destroy(view)
end)
fixture:Destroy()
if not ok5 then
	check(false, "the stands and the board built without an error", tostring(err5))
end

--==============================================================================
say("\n7. The wiring")
--==============================================================================
local Scripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local function source(parent, name)
	local s = parent:FindFirstChild(name)
	return if s then (s :: any).Source else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
local ui = source(Scripts, "PodGuideUI")
check(has(ui, "if e.carousel == nil and d <= CFG.BuildStuds then") and has(ui, "elseif e.carousel ~= nil and d > CFG.FreeStuds then")
		and has(ui, "local near = if e.near then d <= CFG.PreviewFarStuds else d <= CFG.PreviewNearStuds")
		and has(ui, "if since >= CFG.CheckSeconds then") and has(ui, "local waiting = HatchRoll.sealedSpecies(player)")
		and has(ui, "still = StatusText.reducedMotion()") and has(ui, "folder.Archivable = false"),
	"PodGuideUI: pods built near and freed far, pictures near only, checked every CheckSeconds; a first discovery waits "
		.. "for its reveal; still for reduced motion")
local index = source(Scripts, "IndexUI")
check(has(index, "chance.Text = string.format(GUIDE.Words.CardChance, PodGuide.percent(PodGuide.chanceOf(species.Id)))")
		and has(index, "podSizes.Visible = not searching") and has(index, "for i, rate in ipairs(PodGuide.incomes(id)) do")
		and has(index, "showHatch.Text = string.format(GUIDE.Words.HatchesFrom") and has(index, "openAt.Name = \"OpenAt\"")
		and has(index, "stagePodPreview.setModel(podKey, podBuilder, podKind)"),
	"the Almanac: each card's chance, POD SIZES over the page, a plant's income at every size, its own pod and where it "
		.. "hatches from, and an OpenAt for the Bag")
local loadout = source(Scripts, "LoadoutUI")
check(has(loadout, "table.insert(actions, { id = \"inside\", label = GameConfig.PodGuide.Words.WhatsInside })")
		and has(loadout, "openAt:Fire(it.speciesId)"),
	"the Bag: an ordinary pod's menu has WHAT'S INSIDE?, which opens the Almanac at its plant")

say(string.format("\nPodGuideSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
