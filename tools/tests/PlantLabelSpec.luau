--!nocheck
--==============================================================================
-- Steal a Seed :: PlantLabelSpec (2026-10-04, the owner's overhead-label brief)
--
-- The label over a grown creature in a bed, in Edit:
--
--   * WHAT IT SAYS for an ordinary plant, a large-tier one (TITAN / COLOSSAL in
--     the wheel's lettering), a Secret (rarity, name, income -- no size) and the
--     rain event's forms (Pod 1's unsized: no size, never "TINY"; Pod 2's:
--     COLOSSAL). No kg anywhere.
--   * THE RATE IS THE OWNER'S: SeedData.IncomePerSecond times the plot's
--     GardenBoost and the rain, each once -- the product EconomyService.RateFor
--     pays -- never the looker's own pass.
--   * HOW IT IS DRAWN: three lines, no plate, a fixed pixel size, its bottom
--     edge on the crown, depth-tested, faded by camera distance and off past
--     it; RarityFX on Mythic / Divine / Secret words and only while shown; the
--     size and the separator gone, the income centred, with no size; cleaned up.
--   * THE WIRING, read off the source: PlantUI's one render step, the label made
--     once per grown model and dropped with it, PICK UP's selection hiding it,
--     the boost and the rain re-painting it, CashPop starting above it and
--     paying the owner's rate.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local PlantLabel = require(Shared:WaitForChild("PlantLabel"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))

local L = GameConfig.Labels.Plant
local FACTOR = GameConfig.Weather.Attributes.Factor

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

local fixture = Instance.new("Folder")
fixture.Name = "PlantLabelSpecFixture"
fixture.Parent = Workspace
local rainWas = Workspace:GetAttribute(FACTOR)

local function hasKg(c)
	for _, v in pairs(c) do
		if type(v) == "string" and string.find(string.lower(v), "kg", 1, true) then
			return true
		end
	end
	return false
end

local function run()
	say("-- what it says --")
	local rare = PlantLabel.content("toadcap", 3, 1)
	check(rare and rare.rarityText == "RARE" and rare.rarity == "Rare" and rare.name == "TOADCAP"
			and rare.size == "HUGE" and rare.sizeStyle == nil
			and rare.incomePerSecond == SeedData.IncomePerSecond(SeedData.Get("toadcap"), 3)
			and rare.income == "$" .. GameConfig.compact(rare.incomePerSecond) .. "/s"
			and rare.rarityColour == GameConfig.RarityColor.Rare,
		"an ordinary plant: RARE / TOADCAP / HUGE . $N/s, the income the server pays, compacted",
		rare and string.format("%s %s %s %s", rare.rarityText, rare.name, tostring(rare.size), rare.income))
	local titan = PlantLabel.content("toadcap", 6, 1)
	local colossal = PlantLabel.content("toadcap", 7, 1)
	check(titan.size == "TITAN" and titan.sizeStyle == "titan" and colossal.size == "COLOSSAL"
			and colossal.sizeStyle == "colossal",
		"the large tiers: TITAN and COLOSSAL, each in the wheel's own lettering")
	local secret = PlantLabel.content("snarlbloom", SeedData.TierCount, 1)
	check(secret.rarityText == "SECRET" and secret.name == "SNARLBLOOM" and secret.size == nil
			and secret.incomePerSecond == 155000,
		"a Secret: SECRET / SNARLBLOOM and its fixed $155K/s -- no size", secret.income)
	local petal = PlantLabel.content("petalfawn", SeedData.TierCount, 2)
	check(petal.size == nil and petal.incomePerSecond == 189000 * 2,
		"Petalfawn too, its fixed rate times the owner's x2 pass", petal.income)
	local puddle = PlantLabel.content("puddlepod", 1, 1)
	check(puddle.size == nil and puddle.rarityText == "MYTHIC" and puddle.name == "PUDDLEPOD",
		"a rain Pod 1 form: its tier is implementation only -- no size, never \"TINY\"", tostring(puddle.size))
	local puddleBig = PlantLabel.content("puddlepod_colossal", SeedData.TierCount, 1)
	check(puddleBig.size == "COLOSSAL" and puddleBig.sizeStyle == "colossal",
		"a rain Pod 2 form shows the Colossal it is defined as", tostring(puddleBig.size))
	local anyKg = false
	for _, c in ipairs({ rare, titan, colossal, secret, petal, puddle, puddleBig }) do
		anyKg = anyKg or hasKg(c)
	end
	check(not anyKg, "and not one line anywhere says kg")
	check(PlantLabel.content("not_a_species", 1, 1) == nil, "an unknown species gets no label")

	say("\n-- the owner's rate --")
	Workspace:SetAttribute(FACTOR, nil)
	local plot = Instance.new("Folder")
	plot.Name = "SpecPlot"
	plot.Parent = fixture
	check(GameConfig.gardenIncomeMultiplier(plot) == 1, "a plot with no GardenBoost and no rain: x1")
	plot:SetAttribute(GameConfig.Attributes.GardenBoost, 2.5)
	check(GameConfig.gardenIncomeMultiplier(plot) == 2.5, "the owner's published boost: x2.5")
	Workspace:SetAttribute(FACTOR, 1.25)
	check(math.abs(GameConfig.gardenIncomeMultiplier(plot) - 3.125) < 1e-9,
		"and the rain on top, once: x2.5 x1.25", GameConfig.gardenIncomeMultiplier(plot))
	local boosted = PlantLabel.content("toadcap", 3, GameConfig.gardenIncomeMultiplier(plot))
	check(boosted.incomePerSecond == SeedData.IncomePerSecond(SeedData.Get("toadcap"), 3) * 3.125,
		"the label's rate is IncomePerSecond x that, the product RateFor pays", boosted.income)
	plot:SetAttribute(GameConfig.Attributes.GardenBoost, 0 / 0)
	Workspace:SetAttribute(FACTOR, nil)
	check(GameConfig.gardenIncomeMultiplier(plot) == 1 and GameConfig.gardenIncomeMultiplier(nil) == 1,
		"a junk boost or no plot reads as x1, never less")
	local econ = ServerScriptService.SeedGameServer:FindFirstChild("EconomyService")
	local readOk, read = pcall(function()
		return (econ :: any).Source
	end)
	local econSrc = if readOk and type(read) == "string" then read else ""
	check(econSrc:find("local boost = withPass(player, 1) * temporaryBoost(player)", 1, true) ~= nil
			and econSrc:find("return withPass(player, rate) * temporaryBoost(player) * WeatherService.IncomeFactor()",
				1, true) ~= nil,
		"GardenBoost is the pass x the boosts and RateFor adds the rain once: the label multiplies exactly that")

	say("\n-- how far it shows --")
	check(PlantLabel.fade(0) == 1 and PlantLabel.fade(L.NearStuds) == 1 and PlantLabel.fade(L.FarStuds) == 0
			and PlantLabel.fade(L.FarStuds + 100) == 0
			and math.abs(PlantLabel.fade((L.NearStuds + L.FarStuds) / 2) - 0.5) < 1e-9
			and PlantLabel.fade(0 / 0) == 0,
		string.format("whole within %d studs of the camera, fading out to nothing at %d", L.NearStuds, L.FarStuds))
	check(L.NearStuds == 45 and L.FarStuds == 70,
		"measured flat, 45 whole and 70 gone -- set after Play, where the 3D 38 / 58 faded a Colossal's label")

	say("\n-- the billboard --")
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.Size = Vector3.new(2, 1, 2)
	anchor.Parent = fixture
	local holder = Instance.new("Folder")
	holder.Parent = fixture
	local label = PlantLabel.new(holder, anchor, 6.5, 1)
	local gui = label.gui
	local h = PlantLabel.height()
	check(gui:IsA("BillboardGui") and gui.Adornee == anchor and gui.Size == UDim2.fromOffset(L.Width, h)
			and gui.SizeOffset == Vector2.new(0, 0.5) and gui.StudsOffsetWorldSpace == Vector3.new(0, 6.5, 0)
			and gui.AlwaysOnTop == true and gui.LightInfluence == 0 and gui.MaxDistance <= L.FarStuds + 2
			and gui.ResetOnSpawn == false and gui.Enabled == false,
		"a fixed-pixel billboard standing on the crown (its bottom edge at the point), on top (a creature's own "
			.. "eye stalks hid a depth-tested one), unlit, never past its fade, respawn-proof, born off")
	local plate = false
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("GuiObject") and d.BackgroundTransparency < 1 then
			plate = true
		end
	end
	check(not plate, "no plate: nothing behind the words")
	check(label.name.TextSize == L.NameSize and label.rarity.TextSize == L.RaritySize
			and label.name.TextSize > label.rarity.TextSize and label.name.TextSize > label.income.TextSize,
		"the name is the largest line")

	PlantLabel.paint(label, rare)
	check(label.rarity.Text == "RARE" and label.rarity.TextColor3 == GameConfig.RarityColor.Rare
			and label.name.Text == "TOADCAP" and label.size.Visible and label.dot.Visible
			and label.size.Text == "HUGE" and label.size.TextColor3 == rare.sizeColour
			and label.income.Text == rare.income and label.income.TextColor3 == L.Income
			and label.size:FindFirstChild("Prestige") == nil,
		"painted: the rarity in its colour, the name, the size in its tier colour, the income in green")
	PlantLabel.paint(label, colossal)
	check(label.size:FindFirstChild("Prestige") ~= nil and label.glint ~= nil,
		"a Colossal's size word wears the wheel's lettering")
	PlantLabel.paint(label, rare)
	check(label.size:FindFirstChild("Prestige") == nil and label.glint == nil
			and label.size.TextColor3 == rare.sizeColour,
		"and loses it again when the label says HUGE")
	PlantLabel.paint(label, secret)
	check(not label.size.Visible and not label.dot.Visible and label.income.Visible,
		"no size: the size and the separator go, the income stands alone (centred by its row)")

	PlantLabel.paint(label, secret)
	local halo = label.rarity:FindFirstChild("RarityHalo")
	check(gui.ZIndexBehavior == Enum.ZIndexBehavior.Global and label.rarity.ZIndex > 1
			and (halo == nil or (halo.ZIndex < label.rarity.ZIndex and halo.Visible)),
		"a Secret's light keyline twin stands BEHIND its black word (Global layering, the word above layer 1)",
		halo and string.format("twin %d word %d", halo.ZIndex, label.rarity.ZIndex))
	local mythic = PlantLabel.content("supernovus", 3, 1)
	PlantLabel.paint(label, mythic)
	local gradient = label.rarity:FindFirstChild("RarityLight")
	check(gradient and gradient.Enabled, "a Mythic word wears RarityFX's light")
	local before = RarityFX.runningCount()
	PlantLabel.setShown(label, true)
	local running = RarityFX.isRunning(label.rarityFX) or RarityFX.still()
	PlantLabel.setShown(label, false)
	check(running and not RarityFX.isRunning(label.rarityFX) and gui.Enabled == false
			and RarityFX.runningCount() == before,
		"its light runs only while the label is shown, and stops when it is not")

	PlantLabel.paint(label, rare)
	PlantLabel.setShown(label, true)
	PlantLabel.setAlpha(label, 0.5)
	check(math.abs(label.name.TextTransparency - 0.5) < 1e-6 and math.abs(label.income.TextTransparency - 0.5) < 1e-6,
		"half way out: every line at half strength", label.name.TextTransparency)
	PlantLabel.setAlpha(label, 1)
	check(label.name.TextTransparency == 0 and label.income.TextTransparency == 0,
		"and whole again close up")
	check(PlantLabel.drawnHeight(label) == h, "CashPop is told its drawn height while it shows", PlantLabel.drawnHeight(label))
	PlantLabel.setShown(label, false)
	check(PlantLabel.drawnHeight(label) == 0, "and 0 while it does not")
	local phone = PlantLabel.new(holder, anchor, 6.5, L.PhoneScale)
	check(phone.gui.Size == UDim2.fromOffset(L.Width * L.PhoneScale, h * L.PhoneScale)
			and phone.column:FindFirstChildOfClass("UIScale") ~= nil,
		"a touch screen draws the same label at its PhoneScale")
	PlantLabel.destroy(phone)
	PlantLabel.destroy(label)
	check(gui.Parent == nil and not RarityFX.isRunning(label.rarityFX), "destroyed: the billboard gone and its light forgotten")

	say("\n-- the wiring, read --")
	local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local function src(name)
		local s = scripts:FindFirstChild(name)
		local ok, v = pcall(function()
			return (s :: any).Source
		end)
		return if ok and type(v) == "string" then v else ""
	end
	local plantUI, cashPop, pick = src("PlantUI"), src("CashPop"), src("PlantPickUI")
	local function count(s, pattern)
		return select(2, string.gsub(s, pattern, ""))
	end
	check(plantUI:find("alpha = PlantLabel.fade(math.sqrt(d.X * d.X + d.Z * d.Z))", 1, true) ~= nil,
		"PlantUI fades by FLAT distance, so height never dims a tall creature's label")
	check(count(plantUI, "BindToRenderStep%(") == 1 and count(plantUI, "Heartbeat:Connect") == 0
			and count(plantUI, "RenderStepped:Connect") == 0,
		"PlantUI still has one per-frame update, and the labels ride it")
	check(plantUI:find("if panel.stage == STAGE_GROWN then", 1, true) ~= nil
			and plantUI:find("ensureGrown(panel)", 1, true) ~= nil,
		"only a GROWN model gets a label; a pod keeps its clock")
	check(plantUI:find("dropGrown(panel)\n\t\tif panel.readyConn then", 1, true) ~= nil,
		"a model leaving the bed (picked up, removed, replaced by a hatch, the plot released) drops its label")
	check(plantUI:find("GameConfig.gardenIncomeMultiplier(panel.plot)", 1, true) ~= nil
			and plantUI:find("GetAttributeChangedSignal(GameConfig.Attributes.GardenBoost)", 1, true) ~= nil
			and plantUI:find("GetAttributeChangedSignal(GameConfig.Weather.Attributes.Factor)", 1, true) ~= nil,
		"painted at the owner's rate, again when the owner's boost or the rain changes")
	check(plantUI:find("GROWN_LABEL.SelectedAttribute", 1, true) ~= nil
			and pick:find("model:SetAttribute(GameConfig.Labels.Plant.SelectedAttribute, true)", 1, true) ~= nil
			and pick:find("was.model:SetAttribute(GameConfig.Labels.Plant.SelectedAttribute, nil)", 1, true) ~= nil,
		"PICK UP's selection hides the label and gives it back")
	check(cashPop:find("GameConfig.gardenIncomeMultiplier(entry.plot)", 1, true) ~= nil
			and cashPop:find("GameConfig.incomeMultiplier(player))", 1, true) == nil
			and cashPop:find("GameConfig.Labels.Plant.HeightAttribute", 1, true) ~= nil,
		"the cash pop pays out the OWNER's rate and starts above a showing label")
end

local ok, err = pcall(run)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
Workspace:SetAttribute(FACTOR, rainWas)
fixture:Destroy()
say(string.format("\nPlantLabelSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
