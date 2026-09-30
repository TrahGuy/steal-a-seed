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
-- a made-up id, so the spec never depends on the live id (3713212811) staying
-- what it is. The spec sets the copy back to 0 once, to prove a 0 sells nothing.
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

local profile = { Plants = {}, InstantCredits = 0 }
-- Whether the garden can be written. The real SetPlants answers, and a
-- purchase that changes a pod is only answered for on a garden that was.
local plantsWrite = true
-- Whether the owner's profile is one that saves (the real IsPersistent). A
-- receipt that finds nothing to hatch keeps a saved Instant Hatch only for a
-- profile that saves (PlantService.keepForLater, 2026-09-30).
local persistent = true
local PlayerDataService = {
	IsReady = function()
		return true
	end,
	Get = function(player)
		return if player == owner then profile else nil
	end,
	IsPersistent = function(player)
		return player == owner and persistent
	end,
	AddInstantCredits = function(player, delta)
		if player ~= owner then
			return nil
		end
		profile.InstantCredits += delta
		record("AddInstantCredits", player, delta)
		return profile.InstantCredits
	end,
	SetPlants = function(player, list)
		if not plantsWrite then
			return false
		end
		record("SetPlants", player, list)
		return true
	end,
	MarkSeen = function(player, id)
		record("MarkSeen", player, id)
	end,
	RecordTutorial = function(player, step)
		record("RecordTutorial", player, step)
	end,
}

local giveWorks = true
-- The saved record, as CarryService counts it (2026-09-29): how many more rows
-- fit, and whether there is a record at all. A hatch with no room is refused
-- with the reason beside it, as the real GiveHatched refuses.
local storage = { room = 5, known = true }
local CarryService = {
	GiveHatched = function(player, species, tier)
		record("GiveHatched", player, species, tier)
		if not storage.known then
			return false, "NO_RECORD"
		end
		if storage.room < 1 then
			return false, "STORAGE_FULL"
		end
		return giveWorks
	end,
	HeldRoom = function(player)
		record("HeldRoom", player)
		local limit = GameConfig.Save.MaxHeld
		return storage.room, limit - storage.room, storage.known
	end,
	-- Read by the storage-full log line. Nobody here carries a pod.
	IsCarrying = function()
		return false
	end,
	SyncHeldNow = function() end,
}

-- Every line the game says to a player, instead of the wire.
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local said = {}
ActionRefusal.capture(function(player, code)
	table.insert(said, { player = player, code = code })
end)
local function saidCount(code)
	local n = 0
	for _, line in ipairs(said) do
		if line.code == code then
			n += 1
		end
	end
	return n
end

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
	--==========================================================================
	-- EACH ROW CARRIES ITS OWN DEADLINE
	--
	-- Since 2026-09-17 a pod's ready time is HatchAt, saved with the plant, and
	-- these rows set it outright. Written this way the bed is the same bed on any
	-- ladder: what is nearly ready, what has the longest wait and what is already
	-- out do not move when the approved timers change. HatchTimerSpec is where the
	-- ladder itself and the grandfathering of rows WITHOUT a deadline are tested.
	--==========================================================================
	-- Placement ids are handed out in row order, 1 to 5.
	profile.Plants = {
		-- 1: a Tiny pod with most of its wait left
		{ SpeciesId = "nubkin", Tier = 1, PlantedAt = now - 2, HatchAt = now + 28,
			X = -8, Z = -4, Stage = 1, Facing = 0 },
		-- 2: a pod whose clock ran out long ago: ready
		{ SpeciesId = "nubkin", Tier = 1, PlantedAt = now - 100000, HatchAt = now - 99000,
			X = 0, Z = -4, Stage = 1, Facing = 0 },
		-- 3: a heavier pod just planted: the longest wait in the bed
		{ SpeciesId = "petalpip", Tier = 4, PlantedAt = now, HatchAt = now + 360,
			X = 8, Z = -4, Stage = 1, Facing = 0 },
		-- 4: a grown creature, already placed
		{ SpeciesId = "nubkin", Tier = 1, PlantedAt = now - 100000, HatchAt = now - 99000,
			X = -8, Z = 4, Stage = 3, Facing = 0 },
		-- 5: a Tiny pod a few seconds from ready
		{ SpeciesId = "nubkin", Tier = 1, PlantedAt = now - 26, HatchAt = now + 4,
			X = 8, Z = 4, Stage = 1, Facing = 0 },
		-- 6: a pod with minutes to go, and less than pod 3's: the one a purchase
		-- finds the record full for (2026-09-29)
		{ SpeciesId = "spiretip", Tier = 2, PlantedAt = now - 50, HatchAt = now + 200,
			X = 0, Z = 4, Stage = 1, Facing = 0 },
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
	for id = 1, 6 do
		if modelFor(id) then
			built += 1
		end
	end
	check(built == 6, "the whole garden was restored into the plot", built)

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
		check(instant:GetAttribute("RobuxProduct") == LIVE_ID,
			"and the product id, so PromptUI can ask Roblox what THIS player pays (regional pricing)",
			tostring(instant:GetAttribute("RobuxProduct")))
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
	-- 5b. NO ROOM, NO DIALOG (2026-09-29)
	--
	-- The owner's rule: "prevent opening its purchase prompt when storage is
	-- full". The count is CarryService's; the press is answered with the line.
	--==========================================================================
	say("\n-- press, with the record full --")
	task.wait(INSTANT.OfferGapSeconds + 0.1)
	table.clear(said)
	storage.room = 0
	check(refused(owner, 1) and count("HeldRoom") >= 1,
		"with plant storage full, the owner's press opens no purchase dialog")
	check(saidCount("STORAGE_FULL") == 1 and #said == 1 and said[1].player == owner,
		"and the owner is told PLANT STORAGE FULL, once", #said)
	check(refused(owner, 1) and refused(owner, 3) and #said == 1,
		"pressing again, on this pod or another, says nothing more: one line, not one a press", #said)
	check(refused(stranger, 1) and #said == 1,
		"a stranger's press is refused for being a stranger's, and is told nothing", #said)
	-- Room on it or not, a record that has not arrived is not one to sell into.
	storage.known = false
	storage.room = 3
	check(refused(owner, 1) and #said == 1,
		"with no record yet -- the save still arriving -- nothing is offered and nothing is said", #said)
	storage.known = true
	storage.room = 1
	table.clear(trace)
	check(PlantService.OfferInstantHatch(owner, plotModel, 1) == true
			and count("PromptProductPurchase") == 1,
		"with room for one, the very next press opens the dialog: a refused press used up no wait",
		count("PromptProductPurchase"))
	local limit = GameConfig.Save.MaxHeld
	local note = ActionRefusal.Notices.STORAGE_FULL
	check(note ~= nil and note.title == "PLANT STORAGE FULL"
			and string.find(note.detail, string.format("%d/%d", limit, limit), 1, true) ~= nil
			and ActionRefusal.Text.STORAGE_FULL == string.format("Plant storage full (%d/%d).", limit, limit),
		"the line is PLANT STORAGE FULL with the limit's own number, and what makes room",
		note and (note.title .. " / " .. tostring(note.detail)))

	--==========================================================================
	-- 6a. THE RECEIPT THAT FINDS THE RECORD FULL (2026-09-29)
	--
	-- A dialog opens for pod 6 with room for one, and the record fills before
	-- the receipt lands. The hatch is refused like any other and the pod stays
	-- planted; the owner's decision for what the purchase then does is "make
	-- its intended pod ready immediately and persist that state", and answer
	-- for the receipt "only after that benefit is safely recorded". So the
	-- answer is true only when the garden was written with the pod's wait over.
	-- (StoreService's ledger and its save are HatchStorageSpec's.)
	--==========================================================================
	say("\n-- receipt, with the record full --")
	task.wait(INSTANT.OfferGapSeconds + 0.1)
	check(PlantService.OfferInstantHatch(owner, plotModel, 6) == true,
		"with room for one, a dialog opens for another growing pod (pod 6)")
	local model6 = modelFor(6)
	local before6 = model6 and model6:GetAttribute("HatchAt")
	storage.room = 0

	-- First with a garden that cannot be written.
	table.clear(trace)
	table.clear(said)
	plantsWrite = false
	local unwritten = PlantService.InstantHatch(owner)
	plantsWrite = true
	check(unwritten == false and count("GiveHatched") == 1 and last("GiveHatched").args[2].Id == "spiretip",
		"a receipt that finds plant storage full, and a garden that cannot be written: answered false",
		tostring(unwritten))
	check(model6 ~= nil and CollectionService:HasTag(model6, GameConfig.Tags.Planted)
			and promptsOn(model6, "InstantHatchPrompt") == 1 and promptsOn(model6, "HatchPrompt") == 0
			and model6:GetAttribute("Ready") ~= true and model6:GetAttribute("HatchAt") == before6
			and #said == 0,
		"the pod is as it was -- planted, growing, its clock the one it had -- and nothing is said")

	-- Delivered again, and the garden can be written.
	table.clear(trace)
	local asked6 = os.time()
	check(PlantService.InstantHatch(owner) == true,
		"delivered again: the pod that was paid for is made ready, and the receipt answered for")
	check(count("GiveHatched") == 1 and last("GiveHatched").args[2].Id == "spiretip"
			and count("MarkSeen") == 0 and count("RecordTutorial") == 0
			and model6 ~= nil and model6.Parent ~= nil
			and CollectionService:HasTag(model6, GameConfig.Tags.Planted),
		"nothing is handed over, learned or counted: the hatch was refused, and the pod stays planted")
	check(promptsOn(model6, "HatchPrompt") == 1 and promptsOn(model6, "InstantHatchPrompt") == 0
			and model6:GetAttribute("Ready") == true,
		"it is READY: the free Hatch replaces the paid prompt")
	local written = last("SetPlants")
	local row6 = nil
	for _, row in ipairs(if written then written.args[2] else {}) do
		if row.SpeciesId == "spiretip" then
			row6 = row
		end
	end
	check(count("SetPlants") == 1 and written ~= nil and #written.args[2] == 6 and row6 ~= nil
			and row6.Stage == 1 and row6.HatchAt >= asked6 and row6.HatchAt <= os.time()
			and model6:GetAttribute("HatchAt") == row6.HatchAt,
		"the garden is written once, all six still in it, with that pod's wait over",
		row6 and tostring(row6.HatchAt))
	check(saidCount("STORAGE_FULL_READY") == 1 and #said == 1 and said[1].player == owner,
		"the buyer is told: storage full, and the pod is ready to hatch free once there is room", #said)
	check(promptsOn(modelFor(1), "InstantHatchPrompt") == 1 and promptsOn(modelFor(3), "InstantHatchPrompt") == 1
			and promptsOn(modelFor(1), "HatchPrompt") == 0 and promptsOn(modelFor(3), "HatchPrompt") == 0,
		"and no other pod is touched")
	local ready = ActionRefusal.notice("STORAGE_FULL_READY")
	check(ready ~= nil and ready.title == "PLANT STORAGE FULL" and ready.kind == "warning"
			and string.find(string.lower(ready.detail), "ready", 1, true) ~= nil
			and string.find(string.lower(ready.detail), "free", 1, true) ~= nil
			and string.find(string.lower(ready.detail), "room", 1, true) ~= nil,
		"the line says the storage is full, that the pod is ready, and that it hatches free with room",
		ready and (ready.title .. " / " .. tostring(ready.detail)))

	-- The dialog for pod 1 again, for the receipts below.
	storage.room = 1
	task.wait(INSTANT.OfferGapSeconds + 0.1)
	check(PlantService.OfferInstantHatch(owner, plotModel, 1) == true,
		"(with room for one again, the dialog for pod 1 is opened once more)")

	--==========================================================================
	-- 6. THE RECEIPT
	--==========================================================================
	say("\n-- receipt --")
	table.clear(trace)
	local model1 = modelFor(1)
	check(PlantService.InstantHatch(owner) == true,
		"the receipt hatches a pod -- the next delivery, once there is room")
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
	check(saved ~= nil and #saved.args[2] == 5 and not stillThere,
		"the garden is saved without it", saved and #saved.args[2])
	local seen, tutorial = last("MarkSeen"), last("RecordTutorial")
	check(seen ~= nil and seen.args[2] == "nubkin" and tutorial ~= nil and tutorial.args[2] == "hatch",
		"the Almanac learns the species and the tutorial counts it as a hatch")

	-- A receipt hatches the pod that was pressed and no other (the owner,
	-- 2026-09-30): with no note it names none, so pod 3 is pressed first.
	task.wait(INSTANT.OfferGapSeconds + 0.1)
	check(PlantService.OfferInstantHatch(owner, plotModel, 3) == true,
		"(the dialog for pod 3 is opened: the note names it)")
	table.clear(trace)
	giveWorks = false
	check(PlantService.InstantHatch(owner) == false and modelFor(3) ~= nil
		and count("SetPlants") == 0 and count("AddInstantCredits") == 0,
		"nowhere to put the creature: nothing hatches, the pod stays and no credit is kept, so the receipt is retried")
	giveWorks = true

	table.clear(trace)
	check(PlantService.InstantHatch(owner) == true, "delivered again once there is somewhere to put it, it hatches")
	given = last("GiveHatched")
	check(given ~= nil and given.args[2].Id == "petalpip" and given.args[3] == 4 and modelFor(3) == nil,
		"the pod the note still names: pod 3",
		given and string.format("%s tier %s", given.args[2].Id, tostring(given.args[3])))

	--==========================================================================
	-- ONLY READY PODS LEFT (2026-09-30, the owner's option B). This used to
	-- hatch the one that became ready most recently. The owner's decision:
	-- "For an unresolved Instant Hatch receipt, if no pod still has time left,
	-- save one Instant Hatch credit instead of hatching a ready pod." The
	-- receipt around it -- saved first, never twice -- is HatchStorageSpec's.
	--==========================================================================
	table.clear(trace)
	local creditsReady, readyBefore = profile.InstantCredits, saidCount("INSTANT_CREDIT_READY")
	check(PlantService.InstantHatch(owner) == true and count("GiveHatched") == 0 and count("SetPlants") == 0
		and modelFor(6) ~= nil and modelFor(5) ~= nil and modelFor(2) ~= nil
		and profile.InstantCredits == creditsReady + 1 and count("AddInstantCredits") == 1,
		"only ready pods left: none of them is hatched -- they hatch free -- and ONE saved Instant Hatch is kept",
		profile.InstantCredits)
	check(saidCount("INSTANT_CREDIT_READY") == readyBefore + 1, "and the buyer is told their pods are ready")
	table.clear(trace)
	storage.room = 0
	local fullBefore = saidCount("STORAGE_FULL_CREDIT")
	check(PlantService.InstantHatch(owner) == true and count("GiveHatched") == 0
		and modelFor(6) ~= nil and profile.InstantCredits == creditsReady + 2
		and saidCount("STORAGE_FULL_CREDIT") == fullBefore + 1,
		"the same with plant storage full: a second purchase, a second credit, and the storage-full line")
	storage.room = 1

	-- The ready pods hatched by hand, for free, empty the bed of pods.
	for _, id in ipairs({ 6, 5, 2 }) do
		PlantService.HatchByHand(owner, plotModel, id)
	end
	check(modelFor(6) == nil and modelFor(5) == nil and modelFor(2) == nil and modelFor(4) ~= nil,
		"(the ready pods hatch free by hand; the grown creature stays)")

	--==========================================================================
	-- NO UNHATCHED POD AT ALL (2026-09-30). This used to answer false and
	-- leave the receipt waiting. The owner's decision: "if a paid receipt
	-- arrives and the player has no unhatched pod, grant one saved Instant
	-- Hatch credit." The receipt around it -- saved before it is answered for,
	-- never twice -- is HatchStorageSpec's (10f).
	--==========================================================================
	table.clear(trace)
	local creditsBefore, noPodBefore = profile.InstantCredits, saidCount("INSTANT_CREDIT_NO_POD")
	check(PlantService.InstantHatch(owner) == true and count("GiveHatched") == 0
		and modelFor(4) ~= nil and profile.InstantCredits == creditsBefore + 1
		and count("AddInstantCredits") == 1 and count("SetPlants") == 0,
		"no unhatched pod at all: nothing hatches, the grown creature is untouched, and ONE saved Instant "
			.. "Hatch is kept", profile.InstantCredits)
	check(saidCount("INSTANT_CREDIT_NO_POD") == noPodBefore + 1,
		"and the buyer is told it is saved for later")
	table.clear(trace)
	persistent = false
	check(PlantService.InstantHatch(owner) == false and profile.InstantCredits == creditsBefore + 1
		and count("AddInstantCredits") == 0,
		"a profile that can never be saved keeps nothing: the receipt waits")
	persistent = true
	check(PlantService.InstantHatch(stranger) == false and count("AddInstantCredits") == 0,
		"a player with no plot and no saved profile: nothing")
end

-- Whatever happens inside, the plot and the service's loop do not outlive it.
local bodyOk, bodyErr = pcall(body)
ActionRefusal.capture(nil)
if PlantService then
	pcall(PlantService.Init)
end
plotModel:Destroy()
check(bodyOk, "the spec ran to the end", bodyErr)

say(string.format("\nInstantHatchSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
