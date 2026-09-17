--!nocheck
--==============================================================================
-- Steal a Seed :: HatchTimerSpec
--
-- The approved hatch ladder, the per-pod deadline that carries it, and the
-- promise kept to every pod planted before it. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HatchTimerSpec"))
--
-- THE MIGRATION THIS EXISTS FOR. Until 2026-09-17 a pod's wait came out of a
-- curve that topped out at five minutes, and a save held nothing but the time the
-- pod went in. The owner then approved a ladder ending at 75 minutes. Reading the
-- new ladder for an old row would have added over an hour to a Colossal somebody
-- left in the ground overnight -- so a row with no deadline of its own is
-- grandfathered through the old curve, once, and the answer is saved.
--
-- The real SeedData and GameConfig, and the real PlantService restored into a
-- real Level 1 plot dressed by MapService far above the map. PlotService,
-- PlayerDataService, CarryService and MarketplaceService are stand-ins that only
-- RECORD what they are asked, so no save is read or written.
--
-- Not here: a real purchase dialog (InstantHatchSpec covers the receipt), what
-- the countdown looks like (Play), and planting by hand (Play -- a plant needs a
-- character holding a Tool).
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PlantWander = require(Server:WaitForChild("PlantWander"))
local MapService = require(Server:WaitForChild("MapService"))

local out = {}
local pass, fail = 0, 0

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

-- The owner's numbers, written here as well, so that changing the ladder has to
-- be a deliberate change in two files.
local APPROVED = { 30, 60, 150, 360, 900, 2100, 4500 }
local NAMES = { "Tiny", "Big", "Huge", "Mega", "Giant", "Titan", "Colossal" }

--==============================================================================
-- 1. THE SEVEN APPROVED VALUES
--==============================================================================
say("\n-- the ladder --")
do
	local exactOk, risesOk, namesOk = true, true, true
	local detail = ""
	for tier = 1, 7 do
		local got = SeedData.GrowSeconds(tier)
		if got ~= APPROVED[tier] then
			exactOk = false
			detail ..= string.format(" T%d=%s", tier, tostring(got))
		end
		if tier > 1 and got <= SeedData.GrowSeconds(tier - 1) then
			risesOk = false
		end
		if SeedData.TierName(tier) ~= NAMES[tier] then
			namesOk = false
		end
	end
	check(exactOk, "30 / 60 / 150 / 360 / 900 / 2100 / 4500 seconds, exactly", detail)
	check(risesOk, "and each tier waits longer than the one below it")
	check(namesOk, "on the tiers they were approved for: Tiny to Colossal", detail)
	check(SeedData.GrowSeconds(1) == 30 and SeedData.GrowSeconds(7) == 4500,
		"half a minute for a Tiny, an hour and a quarter for a Colossal")
	check(SeedData.GrowSeconds(nil) == 30 and SeedData.GrowSeconds(99) == 4500,
		"a junk tier reads a real rung rather than throwing")

	-- The curve the ladder replaced is still here, and is still the old promise.
	local legacyOk, shorterOk = true, true
	for tier = 1, 7 do
		local old = SeedData.LegacyGrowSeconds(tier)
		if old <= 0 or old ~= old then
			legacyOk = false
		end
		-- Every rung of the new ladder above Big is longer than the old curve ever
		-- was, which is exactly why an old pod may not be measured against it.
		if tier >= 3 and old >= SeedData.GrowSeconds(tier) then
			shorterOk = false
		end
	end
	check(legacyOk, "the old curve is still callable for pods planted under it")
	check(shorterOk, "and from Huge up it is SHORTER than the ladder, so recomputing would extend a wait")
	check(math.abs(SeedData.LegacyGrowSeconds(7) - 300) < 1,
		"a Colossal's old promise was five minutes", SeedData.LegacyGrowSeconds(7))
end

--==============================================================================
-- 2. ONE SOURCE
--
-- Source reads: no second copy of the seven numbers anywhere, and no client
-- deriving a deadline of its own.
--==============================================================================
say("\n-- one source --")
do
	local function sourceOf(instance)
		if instance == nil then
			return nil
		end
		local ok, src = pcall(function()
			return (instance :: any).Source
		end)
		return if ok then src else nil
	end
	local seedSource = sourceOf(Shared:FindFirstChild("SeedData"))
	local ladderCount = 0
	if seedSource then
		for _ in seedSource:gmatch("2100") do
			ladderCount += 1
		end
	end
	check(seedSource ~= nil and ladderCount >= 1,
		"the ladder lives in SeedData", ladderCount)

	local scripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local copies = {}
	for _, name in ipairs({ "PlantUI", "GardenUI", "TutorialUI" }) do
		local src = sourceOf(scripts and scripts:FindFirstChild(name))
		if src and (src:find("4500") or src:find("2100")) then
			table.insert(copies, name)
		end
	end
	check(#copies == 0, "and no client file writes any of the seven numbers down",
		table.concat(copies, ", "))

	local plantSource = sourceOf(Server:FindFirstChild("PlantService"))
	check(plantSource ~= nil and plantSource:find("HatchAt")
			and plantSource:find("LegacyGrowSeconds"),
		"PlantService stamps a deadline and knows the old promise")
	for _, name in ipairs({ "PlantUI", "GardenUI", "TutorialUI" }) do
		local src = sourceOf(scripts and scripts:FindFirstChild(name))
		check(src ~= nil and src:find("HatchAt") ~= nil,
			string.format("%s reads the server's deadline off the model", name))
	end
end

--==============================================================================
-- THE STAND-INS
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end
local function last(name)
	for i = #trace, 1, -1 do
		if trace[i].name == name then
			return trace[i]
		end
	end
	return nil
end

local fakePlayers = {}
fakePlayers.PlayerRemoving = {
	Connect = function()
		return { Disconnect = function() end }
	end,
}
local owner = { Name = "SpecOwner", UserId = 7171, Parent = fakePlayers }

local plotA, plotB = nil, nil
local currentPlot = nil
local assignedFn = nil
local PlotService = {
	OwnerOf = function(plot)
		return if plot ~= nil and (plot == plotA or plot == plotB) then owner else nil
	end,
	-- WHICHEVER PLOT WAS LAST HANDED OVER. PlantService's restore checks that the
	-- plot is still the player's before it reads their save, so a stand-in that
	-- always answered plotA would silently restore nothing into plotB.
	PlotOf = function(player)
		return if player == owner then currentPlot else nil
	end,
	OnAssigned = function(fn)
		-- Held in its own local: a closure written inside the table constructor
		-- cannot see the local the constructor is being assigned to.
		assignedFn = fn
	end,
	OnReleased = function() end,
	OnResizing = function() end,
	OnResized = function() end,
}

local profile = { Plants = {} }
local PlayerDataService = {
	IsReady = function()
		return true
	end,
	Get = function(player)
		return if player == owner then profile else nil
	end,
	SetPlants = function(player, list)
		record("SetPlants", player, list)
	end,
	MarkSeen = function(player, id)
		record("MarkSeen", player, id)
	end,
	RecordTutorial = function(player, step)
		record("RecordTutorial", player, step)
	end,
}

local CarryService = {
	GiveHatched = function(player, species, tier)
		record("GiveHatched", player, species, tier)
		return true
	end,
	SyncHeldNow = function() end,
}

local fakeMarket = {}
function fakeMarket:PromptProductPurchase(player, productId)
	record("PromptProductPurchase", player, productId)
end

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "MarketplaceService" then
		return fakeMarket
	elseif name == "Players" then
		return fakePlayers
	end
	return game:GetService(name)
end

-- The manifest, with an Instant Hatch id this spec owns. The live id is the
-- owner's and may change; the gate is what is under test, not the number.
local SPEC_PRODUCT = 990007
local realItem = nil
for _, item in ipairs(GameConfig.Store.InWorld or {}) do
	if item.kind == "hatch" then
		realItem = item
	end
end
local liveItem = if realItem then table.clone(realItem) else { kind = "hatch", robux = 99 }
liveItem.product = SPEC_PRODUCT
local liveConfig = setmetatable({
	Store = setmetatable({ InWorld = { liveItem } }, { __index = GameConfig.Store }),
}, { __index = GameConfig })

local outerRequire = require
local function loadWith(module, siblings, overrides)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	local env = setmetatable({
		game = fakeGame,
		script = { Name = module.Name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			if overrides and typeof(target) == "Instance" and overrides[target.Name] ~= nil then
				return overrides[target.Name]
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) })
	setfenv(chunk, env)
	return chunk()
end

local function makePlot(name, id)
	local plot = Instance.new("Model")
	plot.Name = name
	plot.Archivable = false
	plot:SetAttribute("PreviewOnly", true)
	plot:SetAttribute(GameConfig.Attributes.PlotId, id)
	plot.Parent = workspace
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	plot:SetAttribute("PlotCF",
		CFrame.lookAt(Vector3.new(0, 820, centreR), Vector3.new(0, 820, 0)))
	plot:SetAttribute("Depth", startDepth)
	MapService.ResizePlot(plot, 1)
	return plot
end

-- Hand a plot over the way PlotService.Start does, and tell the stand-in about
-- it first, because restore() asks whose plot it is.
local function assign(plot)
	currentPlot = plot
	assignedFn(owner, plot)
end

local function podsIn(plot)
	local found = {}
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("Model") and CollectionService:HasTag(d, GameConfig.Tags.Planted) then
			local id = tonumber(d:GetAttribute("PlacementId"))
			if id then
				found[id] = d
			end
		end
	end
	return found
end

local function promptNamed(model, name)
	if not model then
		return nil
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Name == name then
			return d
		end
	end
	return nil
end

--==============================================================================
-- THE GARDEN THIS SPEC RESTORES
--
-- Rows 1 to 7 are one pod per tier, each with a deadline of its own, planted at
-- different times: a saved deadline must be honoured exactly, whatever the ladder
-- says today. Rows 8 and 9 are LEGACY rows with no deadline at all.
--==============================================================================
local now = os.time()
local LEGACY_TIER = 7
local legacyPlantedAt = now - 600 -- ten minutes ago
local plan = {}
for tier = 1, 7 do
	plan[tier] = {
		SpeciesId = "nubkin",
		Tier = tier,
		PlantedAt = now - 5,
		-- Deliberately NOT the ladder's value: the point is that the save wins.
		HatchAt = now + 100 + tier * 10,
		X = -8 + ((tier - 1) % 4) * 5,
		Z = -4 + math.floor((tier - 1) / 4) * 5,
		Stage = 1,
		Facing = 0,
	}
end
-- 8: a Colossal pod planted ten minutes ago under the OLD curve, which promised
-- five minutes. It is owed READY. Under today's ladder it would have 65 minutes
-- left, and that is the bug this row exists to catch.
plan[8] = { SpeciesId = "nubkin", Tier = LEGACY_TIER, PlantedAt = legacyPlantedAt,
	X = 8, Z = 4, Stage = 1, Facing = 0 }
-- 9: a Big pod planted ten seconds ago with no deadline: still growing, and owed
-- the old curve's wait rather than the new one.
plan[9] = { SpeciesId = "nubkin", Tier = 2, PlantedAt = now - 10,
	X = 3, Z = 4, Stage = 1, Facing = 0 }

local PlantService = nil

local function body()
	plotA = makePlot("HatchTimerSpecPlotA", 96)
	plotB = makePlot("HatchTimerSpecPlotB", 95)
	profile.Plants = plan

	local loadOk, loadErr = pcall(function()
		PlantService = loadWith(Server.PlantService, {
			PlotService = PlotService,
			PlayerDataService = PlayerDataService,
			CarryService = CarryService,
			PlantWander = PlantWander,
		}, { GameConfig = liveConfig })
		PlantService.Init()
		PlantService.Start()
	end)
	check(loadOk and assignedFn ~= nil,
		"PlantService loads and starts against the stand-ins", loadErr)
	if not (loadOk and assignedFn) then
		return
	end
	assign(plotA)
	local built = podsIn(plotA)

	--==========================================================================
	-- 3. A SAVED DEADLINE IS THE POD'S DEADLINE
	--==========================================================================
	say("\n-- the saved deadline wins --")
	do
		local stampedOk, exactOk, growingOk = true, true, true
		local detail = ""
		for tier = 1, 7 do
			local model = built[tier]
			local stamped = if model then tonumber(model:GetAttribute("HatchAt")) else nil
			if not model or not stamped then
				stampedOk = false
				detail ..= string.format(" T%d missing", tier)
			elseif stamped ~= plan[tier].HatchAt then
				exactOk = false
				detail ..= string.format(" T%d=%s want %s", tier, tostring(stamped),
					tostring(plan[tier].HatchAt))
			end
			-- Every one of these is in the future, so every one is still a pod
			-- with a countdown and no free Hatch prompt.
			if promptNamed(model, "HatchPrompt") ~= nil then
				growingOk = false
				detail ..= string.format(" T%d already ready", tier)
			end
		end
		check(stampedOk, "every restored pod carries its deadline on the model", detail)
		check(exactOk, "and it is the one from the save, not one worked out again", detail)
		check(growingOk, "a pod whose deadline is in the future is still growing", detail)
	end

	--==========================================================================
	-- 4. A POD FROM BEFORE THE LADDER KEEPS ITS OLD PROMISE
	--==========================================================================
	say("\n-- the old promise --")
	do
		local legacy = built[8]
		local stamped = if legacy then tonumber(legacy:GetAttribute("HatchAt")) else nil
		local owed = legacyPlantedAt + SeedData.LegacyGrowSeconds(LEGACY_TIER)
		check(stamped ~= nil and math.abs(stamped - owed) <= 1,
			"a saved pod with no deadline is given the one the old curve promised",
			tostring(stamped) .. " want " .. tostring(math.floor(owed)))
		check(stamped ~= nil and stamped < now,
			"which for a ten-minute-old Colossal is already in the past")
		check(promptNamed(legacy, "HatchPrompt") ~= nil,
			"so it comes back READY, with the free Hatch prompt on it")
		check(promptNamed(legacy, "InstantHatchPrompt") == nil,
			"and nothing tries to sell a hatch for a pod that is already ready")
		local wouldBe = legacyPlantedAt + SeedData.GrowSeconds(LEGACY_TIER)
		check(stamped ~= nil and stamped < wouldBe - 3000,
			"today's ladder would have added over an hour to it; it did not",
			string.format("%d vs %d", stamped or -1, wouldBe))

		local young = built[9]
		local youngStamped = if young then tonumber(young:GetAttribute("HatchAt")) else nil
		local youngOwed = (now - 10) + SeedData.LegacyGrowSeconds(2)
		check(youngStamped ~= nil and math.abs(youngStamped - youngOwed) <= 1,
			"a legacy pod still growing keeps the rest of its old wait",
			tostring(youngStamped) .. " want " .. tostring(math.floor(youngOwed)))
		check(promptNamed(young, "HatchPrompt") == nil
				and promptNamed(young, "InstantHatchPrompt") ~= nil,
			"and is still offered the paid hatch, not the free one")
	end

	--==========================================================================
	-- 5. THE MIGRATION IS WRITTEN BACK ONCE
	--==========================================================================
	say("\n-- saved back --")
	do
		local saved = last("SetPlants")
		local rows = if saved then saved.args[2] else nil
		local everyRow, matches = true, true
		local detail = ""
		if type(rows) ~= "table" then
			everyRow = false
		else
			local byKey = {}
			for _, row in ipairs(rows) do
				if type(row.HatchAt) ~= "number" or row.HatchAt <= 0 then
					everyRow = false
					detail ..= " a row saved with no deadline"
				end
				byKey[string.format("%d:%d", row.Tier, row.PlantedAt)] = row.HatchAt
			end
			for tier = 1, 7 do
				local got = byKey[string.format("%d:%d", tier, plan[tier].PlantedAt)]
				if got ~= plan[tier].HatchAt then
					matches = false
					detail ..= string.format(" T%d saved %s", tier, tostring(got))
				end
			end
			local legacySaved = byKey[string.format("%d:%d", LEGACY_TIER, legacyPlantedAt)]
			local owed = math.floor(legacyPlantedAt + SeedData.LegacyGrowSeconds(LEGACY_TIER))
			check(legacySaved ~= nil and math.abs(legacySaved - owed) <= 1,
				"the grandfathered deadline is saved, so the old curve is consulted once",
				tostring(legacySaved))
		end
		check(everyRow, "every saved row carries a deadline", detail)
		check(matches, "and an untouched pod's deadline is saved back unchanged", detail)
	end

	--==========================================================================
	-- 6. INSTANT HATCH IS OFFERED ON ALL SEVEN TIERS
	--==========================================================================
	say("\n-- every tier is offered the paid hatch --")
	do
		local everyTier, priceOk, reservedOk = true, true, true
		local detail = ""
		for tier = 1, 7 do
			local prompt = promptNamed(built[tier], "InstantHatchPrompt")
			if not prompt then
				everyTier = false
				detail ..= string.format(" T%d", tier)
			else
				if prompt:GetAttribute("Robux") ~= 99 then
					priceOk = false
					detail ..= string.format(" T%d=%s", tier, tostring(prompt:GetAttribute("Robux")))
				end
				if prompt:GetAttribute("ReservedFor") ~= owner.UserId then
					reservedOk = false
				end
			end
		end
		check(everyTier, "Tiny to Colossal each carry the Instant Hatch prompt", detail)
		check(priceOk, "at 99 Robux on every one of them", detail)
		check(reservedOk, "drawn for the plot's owner")
	end

	--==========================================================================
	-- 7. NO PRODUCT ID, NO OFFER AT ALL
	--
	-- The readiness gate. It is not a tier gate: with an id, section 6 above just
	-- proved all seven are offered.
	--==========================================================================
	say("\n-- a dead price is never drawn --")
	do
		liveItem.product = 0
		assign(plotB)
		local withoutProduct = podsIn(plotB)
		local anyPaid, readyFree = nil, false
		for id, model in pairs(withoutProduct) do
			if promptNamed(model, "InstantHatchPrompt") then
				anyPaid = id
			end
			if promptNamed(model, "HatchPrompt") then
				readyFree = true
			end
		end
		check(anyPaid == nil, "with the product id at 0, no pod anywhere carries the prompt", anyPaid)
		check(readyFree, "while the free Hatch prompt on the ready pod is untouched")
		check(PlantService.OfferInstantHatch(owner, plotB, 1) == false,
			"and a press that arrives anyway is refused rather than charged")
		liveItem.product = SPEC_PRODUCT
	end

	--==========================================================================
	-- 8. READY IS THE DEADLINE, NOT THE LADDER
	--==========================================================================
	say("\n-- ready --")
	do
		-- A pod whose saved deadline has just passed: the tick has not run yet, so
		-- this asks the service directly through the paid path, which refuses a
		-- pod that is ready.
		profile.Plants = {
			{ SpeciesId = "nubkin", Tier = 7, PlantedAt = now - 20, HatchAt = now - 1,
				X = -8, Z = -4, Stage = 1, Facing = 0 },
			{ SpeciesId = "nubkin", Tier = 1, PlantedAt = now, HatchAt = now + 900,
				X = 0, Z = -4, Stage = 1, Facing = 0 },
		}
		assign(plotB)
		local models = podsIn(plotB)
		check(promptNamed(models[1], "HatchPrompt") ~= nil
				and promptNamed(models[1], "InstantHatchPrompt") == nil,
			"a Colossal one second past its deadline is ready and free to hatch")
		check(promptNamed(models[2], "InstantHatchPrompt") ~= nil
				and promptNamed(models[2], "HatchPrompt") == nil,
			"a Tiny fifteen minutes from its deadline is not, whatever a Tiny's ladder wait is")
		check(PlantService.OfferInstantHatch(owner, plotB, 1) == false,
			"and the ready pod cannot be sold a hatch it no longer needs")
		local stage = models[1] and tonumber(models[1]:GetAttribute("Stage"))
		check(stage == CreatureModel.STAGE_POD,
			"a pod past its deadline is still a POD until somebody hatches it", stage)
	end
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

if plotA then
	plotA:Destroy()
end
if plotB then
	plotB:Destroy()
end

say(string.format("\nHatchTimerSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
