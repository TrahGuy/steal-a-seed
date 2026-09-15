--!nocheck
--==============================================================================
-- Steal a Seed :: InstantHatchSpec
--
-- The Instant Hatch prompt and the receipt that pays for it, on the REAL
-- PlantService. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("InstantHatchSpec"))
--
-- PlantService is loaded from its Source with PlotService, PlayerDataService,
-- CarryService, MarketplaceService and Players stood in. A garden is restored
-- through its real OnAssigned path into a real Level 1 plot, dressed by
-- MapService.ResizePlot far above the map: two growing pods, one pod that goes
-- ready while the spec watches, one ready pod and one grown creature. No save is
-- read or written; the stand-ins record what they are asked.
--
-- PlantService sees the manifest through a copy whose Instant Hatch product has
-- a made-up id, because the real one is 0 until the owner creates it. The spec
-- sets the copy back to 0 once, to prove a 0 sells nothing.
--
-- Not here: a real purchase dialog and receipt (a Studio test purchase, once the
-- id exists), StoreService's ledger (StoreSpec), and how PromptUI draws the
-- prompt (Play).
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PlantWander = require(Server:WaitForChild("PlantWander"))
local MapService = require(Server:WaitForChild("MapService"))

local INSTANT = GameConfig.Plant.InstantHatch

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

--==============================================================================
-- THE STAND-INS
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end
local function count(name)
	local n = 0
	for _, t in ipairs(trace) do
		if t.name == name then
			n += 1
		end
	end
	return n
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
local owner = { Name = "SpecOwner", UserId = 5151, Parent = fakePlayers }
local stranger = { Name = "SpecStranger", UserId = 6262, Parent = fakePlayers }

local plotModel = nil
local assigned = nil
local PlotService = {
	OwnerOf = function(plot)
		return if plot ~= nil and plot == plotModel then owner else nil
	end,
	PlotOf = function(player)
		return if player == owner then plotModel else nil
	end,
	OnAssigned = function(fn)
		assigned = fn
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

local giveWorks = true
local CarryService = {
	GiveHatched = function(player, species, tier)
		record("GiveHatched", player, species, tier)
		return giveWorks
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

-- The manifest with a live Instant Hatch id.
local LIVE_ID = 990001
local realItem = nil
for _, item in ipairs(GameConfig.Store.InWorld or {}) do
	if item.kind == "hatch" then
		realItem = item
	end
end
local liveItem = if realItem then table.clone(realItem) else { kind = "hatch", robux = 99 }
liveItem.product = LIVE_ID
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

--==============================================================================
-- 1. THE MANIFEST AND THE KEY
--==============================================================================
say("\n-- manifest --")
check(realItem ~= nil and realItem.robux == 99 and realItem.key == "instanthatch",
	"Store.InWorld sells Instant Hatch at 99 Robux", realItem and realItem.robux)
check(INSTANT.Key ~= Enum.KeyCode.E and INSTANT.GamepadKey ~= Enum.KeyCode.ButtonX,
	"it has its own key and button, so it can never take E or ButtonX from a ready pod's free Hatch",
	tostring(INSTANT.Key) .. " / " .. tostring(INSTANT.GamepadKey))

--==============================================================================
-- 2. A REAL PLOT AND A RESTORED GARDEN
--==============================================================================
plotModel = Instance.new("Model")
plotModel.Name = "InstantHatchSpecPlot"
plotModel.Archivable = false
plotModel:SetAttribute("PreviewOnly", true)
plotModel:SetAttribute(GameConfig.Attributes.PlotId, 97)
plotModel.Parent = workspace
do
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	plotModel:SetAttribute("PlotCF",
		CFrame.lookAt(Vector3.new(0, 760, centreR), Vector3.new(0, 760, 0)))
	plotModel:SetAttribute("Depth", startDepth)
end

local PlantService = nil

local function modelFor(id)
	for _, d in ipairs(plotModel:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("PlacementId") == id
			and CollectionService:HasTag(d, GameConfig.Tags.Planted) then
			return d
		end
	end
	return nil
end

local function promptsOn(model, name)
	local n, found = 0, nil
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.Name == name then
				n += 1
				found = d
			end
		end
	end
	return n, found
end

local function body()
	MapService.ResizePlot(plotModel, 1)

	local now = os.time()
	local grow1 = SeedData.GrowSeconds(1)
	-- Placement ids are handed out in row order, 1 to 5.
	profile.Plants = {
		-- 1: a Tiny pod two seconds in: a short wait left
		{ SpeciesId = "nubkin", Tier = 1, PlantedAt = now - 2, X = -8, Z = -4, Stage = 1, Facing = 0 },
		-- 2: a pod whose clock ran out long ago: ready
		{ SpeciesId = "nubkin", Tier = 1, PlantedAt = now - 100000, X = 0, Z = -4, Stage = 1, Facing = 0 },
		-- 3: a heavier pod planted this second: the longest wait in the bed
		{ SpeciesId = "petalpip", Tier = 4, PlantedAt = now, X = 8, Z = -4, Stage = 1, Facing = 0 },
		-- 4: a grown creature, already placed
		{ SpeciesId = "nubkin", Tier = 1, PlantedAt = now - 100000, X = -8, Z = 4, Stage = 3, Facing = 0 },
		-- 5: a Tiny pod about two seconds from ready
		{ SpeciesId = "nubkin", Tier = 1, PlantedAt = now - math.floor(grow1) + 2, X = 8, Z = 4,
			Stage = 1, Facing = 0 },
	}

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
	check(loadOk and assigned ~= nil, "PlantService loads and starts against the stand-ins", loadErr)
	if not (loadOk and assigned) then
		return
	end
	assigned(owner, plotModel)

	--==========================================================================
	-- 3. WHO GETS WHICH PROMPT
	--==========================================================================
	say("\n-- prompts --")
	local built = 0
	for id = 1, 5 do
		if modelFor(id) then
			built += 1
		end
	end
	check(built == 5, "the whole garden was restored into the plot", built)

	local i1, instant = promptsOn(modelFor(1), "InstantHatchPrompt")
	local h1 = promptsOn(modelFor(1), "HatchPrompt")
	local i3 = promptsOn(modelFor(3), "InstantHatchPrompt")
	check(i1 == 1 and h1 == 0 and i3 == 1,
		"a growing pod carries exactly one Instant Hatch prompt and no free Hatch",
		string.format("pod1 %d/%d pod3 %d", i1, h1, i3))
	local i2 = promptsOn(modelFor(2), "InstantHatchPrompt")
	local h2 = promptsOn(modelFor(2), "HatchPrompt")
	check(i2 == 0 and h2 == 1, "a ready pod carries the free Hatch and no price",
		string.format("%d/%d", i2, h2))
	local i4 = promptsOn(modelFor(4), "InstantHatchPrompt")
	local h4 = promptsOn(modelFor(4), "HatchPrompt")
	check(i4 == 0 and h4 == 0, "a grown creature carries neither", string.format("%d/%d", i4, h4))

	if instant then
		local model1 = modelFor(1)
		check(instant.Parent == model1.PrimaryPart, "it hangs off the pod's PrimaryPart, where PromptUI looks")
		check(instant.Style == Enum.ProximityPromptStyle.Custom
			and instant.ActionText == INSTANT.ActionText
			and instant.KeyboardKeyCode == INSTANT.Key
			and instant.GamepadKeyCode == INSTANT.GamepadKey
			and instant.HoldDuration == 0
			and instant.MaxActivationDistance == GameConfig.Plant.RangeStuds
			and instant.RequiresLineOfSight == false,
			"custom style, its own verb and key, no hold, the planting range",
			string.format("%s %q %s %s hold=%s range=%s", tostring(instant.Style), instant.ActionText,
				tostring(instant.KeyboardKeyCode), tostring(instant.GamepadKeyCode),
				tostring(instant.HoldDuration), tostring(instant.MaxActivationDistance)))
		check(instant:GetAttribute("Robux") == liveItem.robux
			and instant:GetAttribute("ReservedFor") == owner.UserId
			and instant:GetAttribute("OverPodLabel") == true,
			"it carries the price, the owner's id and the stack-over-label flag for PromptUI",
			string.format("%s %s %s", tostring(instant:GetAttribute("Robux")),
				tostring(instant:GetAttribute("ReservedFor")), tostring(instant:GetAttribute("OverPodLabel"))))
	end

	--==========================================================================
	-- 4. THE TICK KEEPS IT RIGHT
	--
	-- Pod 5 runs out of clock while this waits, and pod 1 has its prompt
	-- destroyed from outside, the way a rebuilt model would lose it.
	--==========================================================================
	say("\n-- tick --")
	if instant then
		instant:Destroy()
	end
	task.wait(4.2)
	local i1b = promptsOn(modelFor(1), "InstantHatchPrompt")
	local i3b = promptsOn(modelFor(3), "InstantHatchPrompt")
	check(i1b == 1 and i3b == 1, "a missing Instant Hatch prompt is rebuilt, and no pod collects a second one",
		string.format("pod1 %d pod3 %d", i1b, i3b))
	local i5 = promptsOn(modelFor(5), "InstantHatchPrompt")
	local h5 = promptsOn(modelFor(5), "HatchPrompt")
	check(i5 == 0 and h5 == 1, "when the clock runs out, the free Hatch replaces the paid one",
		string.format("instant %d, hatch %d", i5, h5))

	--==========================================================================
	-- 5. PRESSING IT
	--==========================================================================
	say("\n-- press --")
	-- Each refusal is checked on a clean trace, so one that fails does not make
	-- the next one fail with it.
	local function refused(player, id)
		table.clear(trace)
		return PlantService.OfferInstantHatch(player, plotModel, id) == false
			and count("PromptProductPurchase") == 0
	end
	check(refused(stranger, 1), "a stranger's press on the owner's pod opens nothing")
	check(refused(owner, 2), "a ready pod is not sold: E hatches it for free")
	check(refused(owner, 4), "a grown creature is not sold a hatch")
	check(refused(owner, 99), "an id that is not in the bed opens nothing")

	liveItem.product = 0
	check(refused(owner, 1), "with the product id still 0, pressing opens nothing")
	liveItem.product = LIVE_ID

	table.clear(trace)
	check(PlantService.OfferInstantHatch(owner, plotModel, 1) == true
		and count("PromptProductPurchase") == 1,
		"the owner's press on a growing pod opens the purchase dialog", count("PromptProductPurchase"))
	local asked = last("PromptProductPurchase")
	check(asked ~= nil and asked.args[1] == owner and asked.args[2] == LIVE_ID,
		"for the owner, and for the Instant Hatch product",
		asked and tostring(asked.args[2]))
	check(PlantService.OfferInstantHatch(owner, plotModel, 1) == false
		and count("PromptProductPurchase") == 1,
		"a second press straight after opens no second dialog")

	--==========================================================================
	-- 6. THE RECEIPT
	--==========================================================================
	say("\n-- receipt --")
	table.clear(trace)
	local model1 = modelFor(1)
	check(PlantService.InstantHatch(owner) == true, "the receipt hatches a pod")
	local given = last("GiveHatched")
	check(given ~= nil and given.args[1] == owner and given.args[2].Id == "nubkin" and given.args[3] == 1,
		"the pod that was pressed (pod 1) hatches, not the one with the longest wait",
		given and string.format("%s tier %s", given.args[2].Id, tostring(given.args[3])))
	check(model1 ~= nil and not CollectionService:HasTag(model1, GameConfig.Tags.Planted)
		and modelFor(3) ~= nil,
		"pod 1's shell bursts out of the bed, and the other pods stay")
	local saved = last("SetPlants")
	local stillThere = false
	for _, row in ipairs(if saved then saved.args[2] else {}) do
		if row.PlantedAt == profile.Plants[1].PlantedAt and row.Tier == 1 and row.Stage == 1 then
			stillThere = true
		end
	end
	check(saved ~= nil and #saved.args[2] == 4 and not stillThere,
		"the garden is saved without it", saved and #saved.args[2])
	local seen, tutorial = last("MarkSeen"), last("RecordTutorial")
	check(seen ~= nil and seen.args[2] == "nubkin" and tutorial ~= nil and tutorial.args[2] == "hatch",
		"the Almanac learns the species and the tutorial counts it as a hatch")

	table.clear(trace)
	giveWorks = false
	check(PlantService.InstantHatch(owner) == false and modelFor(3) ~= nil
		and count("SetPlants") == 0,
		"nowhere to put the creature: nothing hatches and the pod stays, so the receipt is retried")
	giveWorks = true

	table.clear(trace)
	check(PlantService.InstantHatch(owner) == true, "a receipt with no note still hatches")
	given = last("GiveHatched")
	check(given ~= nil and given.args[2].Id == "petalpip" and given.args[3] == 4 and modelFor(3) == nil,
		"with no note, the pod with the longest wait left hatches (pod 3)",
		given and string.format("%s tier %s", given.args[2].Id, tostring(given.args[3])))

	table.clear(trace)
	check(PlantService.InstantHatch(owner) == true and modelFor(5) == nil and modelFor(2) ~= nil,
		"only ready pods left: the one that was ready most recently hatches first (pod 5)")
	check(PlantService.InstantHatch(owner) == true and modelFor(2) == nil,
		"then the other one (pod 2)")

	table.clear(trace)
	check(PlantService.InstantHatch(owner) == false and count("GiveHatched") == 0
		and modelFor(4) ~= nil,
		"no unhatched pod at all: nothing hatches, the grown creature is untouched, the receipt waits")
	check(PlantService.InstantHatch(stranger) == false, "a player with no plot: nothing")
end

-- Whatever happens inside, the plot and the service's loop do not outlive it.
local bodyOk, bodyErr = pcall(body)
if PlantService then
	pcall(PlantService.Init)
end
plotModel:Destroy()
check(bodyOk, "the spec ran to the end", bodyErr)

say(string.format("\nInstantHatchSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
