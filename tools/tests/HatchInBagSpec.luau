--!nocheck
--==============================================================================
-- Steal a Seed :: HatchInBagSpec (2026-10-09)
--
-- PODS HATCH IN THE BAG: the owner's Phase 1, "More stealing, less waiting"
-- (KB/STEAL-MORE-PLAN.md). Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HatchInBagSpec"))
--
-- The owner's approved rules ("approve, let terminal work", relayed 2026-10-09):
--
--   1. a pod's wait starts when it is banked, saved on its Bag row as an
--      absolute deadline; pods never take a bed; HATCH is the bed's own hold;
--      there is a HATCH ALL; the same hatch moment plays;
--   2. pods have their own room, 60; plants keep their 24; a steal is refused
--      only at 60 pods;
--   3. the hatch ladder is kept;
--   4. a hatched plant goes straight into a free bed, else into the Bag;
--
-- and with them: Instant Hatch moves to a growing Bag pod (the same product and
-- the same saved credits); an old save's planted pods keep growing and hatch
-- where they stand; Bag pods with no deadline get now + their grow time at
-- load; and since 2026-10-10 a pod may go in a bed again, with the time it has
-- left (refused 10-09 to 10-10 with "Pods hatch in your Bag now").
--
-- THE REAL PlantService AND THE REAL CarryService, each loaded from its source,
-- the hatch roll switched OFF (HatchRollSpec and HatchDeliverySpec have it on)
-- so a bed's plant stands up within a few seconds. What stands in: PlotService
-- (a plot with an owner), the profile store, the Players service, the purchase
-- dialog, and the players -- tables whose Backpack and body are real instances
-- (HatchDeliverySpec's). Their ids are simulated, from 90,000,000,000. The bank
-- at the red line is StorageDoorsSpec's (its deadline is checked there); the
-- Bag's buttons are a client's, and Play's.
--
-- NOTHING IS BOUGHT AND NO SAVE IS OPENED.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PlayerDataService = require(Server:WaitForChild("PlayerDataService"))
local PlantWander = require(Server:WaitForChild("PlantWander"))
local MapService = require(Server:WaitForChild("MapService"))
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))

local BAG = GameConfig.HatchInBag
local HATCH = GameConfig.Plant.Hatch
local KG = GameConfig.Attributes.CarryingKg
local ITEM = GameConfig.Attributes.ItemId
local MAX_HELD = GameConfig.Save.MaxHeld
local MAX_PODS = GameConfig.Save.MaxPods
-- A level-1 plot's beds.
local CAP = GameConfig.PlotTiers[1].capacity
-- The owner's ladder (2026-09-17), asserted at load in SeedData: kept.
local LADDER = { 30, 60, 150, 360, 900, 2100, 4500 }
-- With the roll off, a bed's plant stands up after the burst, the rise, the
-- label and its fade -- the starter pod's rule.
local STANDS_UP = GameConfig.Plant.BurstSeconds + HATCH.Reveal.Seconds + HATCH.Label.Seconds
	+ HATCH.Label.FadeSeconds

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
-- LOADING A MODULE WITH SOMETHING ELSE IN ITS HANDS (HatchDeliverySpec's)
--==============================================================================
local outerRequire = require
local function loadWith(module, siblings, overrides, gameStandIn)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	local env = setmetatable({
		game = gameStandIn or game,
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

local rollConfig = setmetatable({ Enabled = false, StudioPreview = false }, { __index = HATCH.Roll })
local hatchConfig = setmetatable({ Roll = rollConfig }, { __index = HATCH })
-- No gap between purchase dialogs, so presses can follow each other.
local instantConfig = setmetatable({ OfferGapSeconds = 0 }, { __index = GameConfig.Plant.InstantHatch })
local plantConfig = setmetatable({ Hatch = hatchConfig, InstantHatch = instantConfig },
	{ __index = GameConfig.Plant })
local SPEC_PRODUCT = 990091
local hatchItem = { kind = "hatch", robux = 99, product = SPEC_PRODUCT }
for _, item in ipairs(GameConfig.Store.InWorld or {}) do
	if item.kind == "hatch" then
		hatchItem = table.clone(item)
		hatchItem.product = SPEC_PRODUCT
	end
end
local liveConfig = setmetatable({
	Plant = plantConfig,
	Store = setmetatable({ InWorld = { hatchItem } }, { __index = GameConfig.Store }),
}, { __index = GameConfig })

--==============================================================================
-- THE PLAYERS, AND THE SERVICE THEY ARE IN
--==============================================================================
local Players = {
	PlayerRemoving = {
		Connect = function()
			return { Disconnect = function() end }
		end,
	},
	PlayerAdded = {
		Connect = function()
			return { Disconnect = function() end }
		end,
	},
	GetPlayers = function()
		return {}
	end,
}
local fakeMarket = {}
function fakeMarket:PromptProductPurchase() end
local fakeGame = {}
function fakeGame:GetService(name)
	if name == "MarketplaceService" then
		return fakeMarket
	elseif name == "Players" then
		return Players
	end
	return game:GetService(name)
end

local CarryService = nil
local PlantService = nil
local fixture = Instance.new("Folder")
fixture.Name = "HatchInBagSpecFixture"
fixture.Parent = Workspace

local function living(name, userId)
	local childAdded = Instance.new("BindableEvent")
	local characterAdded = Instance.new("BindableEvent")
	local characterRemoving = Instance.new("BindableEvent")
	local attrs = {}
	local p = {
		Name = name,
		UserId = userId,
		Parent = Players,
		Character = nil,
		ChildAdded = childAdded.Event,
		CharacterAdded = characterAdded.Event,
		CharacterRemoving = characterRemoving.Event,
		_backpack = nil,
		_fire = { childAdded = childAdded, characterAdded = characterAdded,
			characterRemoving = characterRemoving },
	}
	function p.SetAttribute(_, k, v)
		attrs[k] = v
	end
	function p.GetAttribute(_, k)
		return attrs[k]
	end
	function p.FindFirstChildOfClass(self, className)
		local backpack = self._backpack
		if className == "Backpack" and backpack and backpack.Parent then
			return backpack
		end
		return nil
	end
	return p
end

local function newBackpack(p, announce)
	local backpack = Instance.new("Backpack")
	backpack.Parent = fixture
	p._backpack = backpack
	if announce then
		p._fire.childAdded:Fire(backpack)
	end
	return backpack
end

-- A body with a root where `at` says: frontOf measures from it, PlaceAt needs it.
local function newBody(p, at, announce)
	local body = Instance.new("Model")
	body.Name = p.Name .. "Body"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.Transparency = 1
	root.CFrame = at or CFrame.new(0, 5000, 0)
	root.Parent = body
	body.PrimaryPart = root
	body.Parent = fixture
	p.Character = body
	if announce then
		p._fire.characterAdded:Fire(body)
	end
	return body
end

-- Every plant or pod Tool this player has, in the bag and in the hands.
local function toolsOf(p)
	local found = {}
	for _, container in ipairs({ p._backpack, p.Character }) do
		if container and container.Parent then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and type(tool:GetAttribute("SpeciesId")) == "string" then
					table.insert(found, tool)
				end
			end
		end
	end
	return found
end

local function grownTools(p)
	local found = {}
	for _, tool in ipairs(toolsOf(p)) do
		if tool:GetAttribute("Hatched") == true then
			table.insert(found, tool)
		end
	end
	return found
end

local function podTools(p)
	local found = {}
	for _, tool in ipairs(toolsOf(p)) do
		if tool:GetAttribute("Hatched") ~= true then
			table.insert(found, tool)
		end
	end
	return found
end

local function toolOfItem(p, item)
	for _, tool in ipairs(toolsOf(p)) do
		if tool:GetAttribute(ITEM) == item then
			return tool
		end
	end
	return nil
end

local function podTool(p, id, tier)
	for _, tool in ipairs(podTools(p)) do
		if tool:GetAttribute("SpeciesId") == id and tool:GetAttribute(KG) == tier then
			return tool
		end
	end
	return nil
end

--==============================================================================
-- THE PROFILE STORE
--==============================================================================
local STUBBED = { "IsReady", "Get", "SetHeld", "SetPlants", "MarkSeen", "RecordTutorial", "IsPersistent",
	"AddInstantCredits", "MintItem", "TakeFirstCatch" }
local real = {}
for _, name in ipairs(STUBBED) do
	real[name] = PlayerDataService[name]
end
local ready = {}
local profiles = {}
local tutorials = {}

PlayerDataService.IsReady = function(p)
	return ready[p] == true
end
PlayerDataService.Get = function(p)
	return if ready[p] then profiles[p] else nil
end
PlayerDataService.SetHeld = function(p, rows)
	if not profiles[p] or type(rows) ~= "table" then
		return false
	end
	profiles[p].Held = rows
	return true
end
PlayerDataService.SetPlants = function(p, rows)
	if not profiles[p] or type(rows) ~= "table" then
		return false
	end
	profiles[p].Plants = rows
	return true
end
PlayerDataService.MarkSeen = function(p, id)
	local almanac = profiles[p] and profiles[p].Almanac
	if not almanac or almanac[id] then
		return false
	end
	almanac[id] = true
	return true
end
PlayerDataService.RecordTutorial = function(p, step)
	table.insert(tutorials, { who = p, step = step })
	return true
end
PlayerDataService.IsPersistent = function(p)
	return ready[p] == true
end
PlayerDataService.AddInstantCredits = function(p, delta)
	local profile = if ready[p] then profiles[p] else nil
	if not profile or type(delta) ~= "number" or delta == 0 then
		return nil
	end
	local balance = (profile.InstantCredits or 0) + delta
	if balance < 0 then
		return nil
	end
	profile.InstantCredits = balance
	return balance
end
PlayerDataService.MintItem = function(p)
	local profile = profiles[p]
	if not profile then
		return nil
	end
	local n = profile.NextItem or 5000
	profile.NextItem = n + 1
	return "m" .. tostring(n)
end
PlayerDataService.TakeFirstCatch = function()
	return false
end

local function logged(p, step)
	for _, t in ipairs(tutorials) do
		if t.who == p and t.step == step then
			return true
		end
	end
	return false
end

local said = {}
ActionRefusal.capture(function(player, code)
	table.insert(said, { who = player, code = code })
end)
local function saidTo(p, code)
	local n = 0
	for _, line in ipairs(said) do
		if line.who == p and line.code == code then
			n += 1
		end
	end
	return n
end

-- Rows, as a save holds them.
local function podRow(id, tier, item, dueIn)
	return { Id = id, Tier = tier, Hatched = false, Item = item, HatchAt = os.time() + dueIn }
end
local function plantRow(id, tier, item)
	return { Id = id, Tier = tier, Hatched = true, Item = item }
end
local function rowOfItem(profile, item)
	for _, row in ipairs(profile.Held) do
		if row.Item == item then
			return row
		end
	end
	return nil
end
local function plantRows(profile)
	local n = 0
	for _, row in ipairs(profile.Held) do
		if row.Hatched == true then
			n += 1
		end
	end
	return n
end
-- `n` grown plants in a garden, each with an item of its own.
local function grownGarden(n, tag)
	local rows = {}
	local stamp = os.time()
	for i = 1, n do
		table.insert(rows, { SpeciesId = "nubkin", Tier = 1, PlantedAt = stamp - 100, HatchAt = stamp - 100,
			X = -12 + i * 3, Z = -4, Stage = 3, Facing = 0, Item = (tag or "g") .. i })
	end
	return rows
end
local function gardenRowOf(profile, id, tier)
	for _, row in ipairs(profile.Plants) do
		if row.SpeciesId == id and row.Tier == tier then
			return row
		end
	end
	return nil
end

--==============================================================================
-- THE PLOTS
--==============================================================================
local plotOf, ownerOf = {}, {}
local assignedFn = nil
local PlotService = {
	OwnerOf = function(plot)
		return if plot ~= nil then ownerOf[plot] else nil
	end,
	PlotOf = function(p)
		return plotOf[p]
	end,
	OnAssigned = function(fn)
		assignedFn = fn
	end,
	OnReleased = function() end,
	OnResizing = function() end,
	OnResized = function() end,
}

local plots = {}
local function newPlot()
	local index = #plots + 1
	local plot = Instance.new("Model")
	plot.Name = "HatchInBagSpecPlot" .. index
	plot.Archivable = false
	plot:SetAttribute("PreviewOnly", true)
	plot:SetAttribute(GameConfig.Attributes.PlotId, 500 + index)
	plot.Parent = Workspace
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	local y = 3600 + index * 60
	plot:SetAttribute("PlotCF", CFrame.lookAt(Vector3.new(0, y, centreR), Vector3.new(0, y, 0)))
	plot:SetAttribute("Depth", startDepth)
	MapService.ResizePlot(plot, 1)
	table.insert(plots, plot)
	return plot
end

-- Grown plants standing in the plot (Stage 3 models).
local function grownModelsIn(plot)
	local n = 0
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("PlacementId") ~= nil and d:GetAttribute("Stage") == 3
			and CollectionService:HasTag(d, GameConfig.Tags.Planted) then
			n += 1
		end
	end
	return n
end

local reveals = {}
local dialogs = {}

-- Here, armed, with a garden and a Bag. `at` is where they stand: at home (on
-- their plot) unless given.
local function arrive(name, userId, garden, held, at)
	local p = living(name, userId)
	profiles[p] = { Plants = garden or {}, Held = held or {}, Almanac = {}, InstantCredits = 0, NextItem = 5000,
		Receipts = {} }
	ready[p] = true
	local plot = newPlot()
	newBackpack(p, false)
	newBody(p, at or (plot:GetPivot() + Vector3.new(0, 4, 0)), false)
	CarryService.WatchHeld(p)
	CarryService.RestoreHeld(p)
	local deadline = os.clock() + 5
	while not CarryService.IsHeldRestored(p) and os.clock() < deadline do
		task.wait(0.05)
	end
	plotOf[p] = plot
	ownerOf[plot] = p
	assignedFn(p, plot)
	return p, plot, profiles[p]
end

-- A teardown step, followed by the stray syncs that land in a real one.
local function step(p, fn)
	fn()
	CarryService.SyncHeldNow(p)
	task.wait(0.05)
	CarryService.SyncHeldNow(p)
end

-- A death, in the engine's order.
local function die(p)
	local pack, body = p._backpack, p.Character
	step(p, function()
		p._fire.characterRemoving:Fire(body)
	end)
	step(p, function()
		p.Character = nil
		body:Destroy()
	end)
	step(p, function()
		pack:Destroy()
	end)
	local newPack = newBackpack(p, false)
	step(p, function()
		p._fire.childAdded:Fire(newPack)
	end)
	local newBodyModel = newBody(p, nil, false)
	step(p, function()
		p._fire.characterAdded:Fire(newBodyModel)
	end)
	task.wait(0.6)
end

local function body()
	local HatchRoll = loadWith(Shared.HatchRoll, { GameConfig = liveConfig, SeedData = SeedData })
	local loadOk, loadErr = pcall(function()
		CarryService = loadWith(Server.CarryService, {
			NestService = require(Server:WaitForChild("NestService")),
			MapService = MapService,
			PlayerDataService = PlayerDataService,
			Metrics = require(Server:WaitForChild("Metrics")),
			GuardianCatch = require(Server:WaitForChild("GuardianCatch")),
			CarryGuard = require(Server:WaitForChild("CarryGuard")),
		}, nil, fakeGame)
		PlantService = loadWith(Server.PlantService, {
			PlotService = PlotService,
			PlayerDataService = PlayerDataService,
			CarryService = CarryService,
			PlantWander = PlantWander,
			GardenFrame = require(Server:WaitForChild("GardenFrame")),
		}, { GameConfig = liveConfig, HatchRoll = HatchRoll }, fakeGame)
		PlantService.Init()
		PlantService.Start()
	end)
	check(loadOk and assignedFn ~= nil and HatchRoll.live() == false,
		"the real PlantService loads over the real CarryService, with the roll switched off", loadErr)
	if not (loadOk and assignedFn) then
		return
	end
	PlantService.OnRevealed(function(payload)
		table.insert(reveals, payload)
	end)
	PlantService.usePrompt(function(player, productId)
		table.insert(dialogs, { who = player, product = productId })
	end)

	--==========================================================================
	say("\n-- 1. the rules, in config --")
	--==========================================================================
	do
		check(MAX_PODS == 60 and MAX_HELD == 24, "pods have a room of 60; plants keep their 24")
		local verbs = { BAG.Hatch, BAG.HatchAll, BAG.Instant, BAG.Reply }
		local MY = GameConfig.Plant.MyPlants
		local others = { GameConfig.Plant.PlaceAction, GameConfig.Plant.PickUpAction, HATCH.Action,
			MY.Plant, MY.Return, MY.Best, MY.Clear, MY.Reply }
		local distinct, seen = true, {}
		for _, verb in ipairs(verbs) do
			if type(verb) ~= "string" or verb == "" or seen[verb] or table.find(others, verb) then
				distinct = false
			end
			seen[verb] = true
		end
		check(distinct, "the Bag's four verbs are its own, beside every other verb on the GameEvent remote")
		check(BAG.Icons.Hatch == "rbxassetid://70562570593192"
				and BAG.Icons.InstantHatch == "rbxassetid://111764150121238"
				and BAG.Icons.Timer == "rbxassetid://111370496768773"
				and BAG.Icons.Ready == "rbxassetid://131185686807584"
				and BAG.IconCropOffset == Vector2.new(41, 41) and BAG.IconCropSize == Vector2.new(430, 430),
			"the owner's four icons, and the one crop that fits all of them")
		check(BAG.RevealAtBedStuds < HATCH.HearingStuds and BAG.AllGapSeconds > 0 and BAG.Attribute == "HatchAt",
			"the moment plays at the bed only within earshot, and HATCH ALL spaces its moments")
		local kept = true
		for tier, seconds in ipairs(LADDER) do
			if SeedData.GrowSeconds(tier) ~= seconds then
				kept = false
			end
		end
		check(kept, "the hatch ladder is kept: 30 s, 1 m, 2 m 30, 6 m, 15 m, 35 m, 1 h 15")
		-- PlaceAt no longer refuses a pod (2026-10-10, pods go in beds again); the
		-- words stay for a server that still sends POD.
		check(ActionRefusal.Text.POD_IN_BAG == "Pods hatch in your Bag now"
				and ActionRefusal.fromPlacement("POD") == "POD_IN_BAG",
			"the old POD refusal still has its words, for a server that still sends it")
	end

	--==========================================================================
	say("\n-- 2. an old save's Bag pods get their wait at load --")
	--==========================================================================
	do
		local before = os.time()
		local loaded = ProfileSchema.Sanitise({ Held = {
			{ Id = "nubkin", Tier = 2, Hatched = false, Item = "7" },
			{ Id = "nubkin", Tier = 1, Hatched = false, Item = "8", HatchAt = 123 },
			{ Id = "petalpip", Tier = 3, Hatched = false, Item = "9", HatchAt = before + 1e7 },
			{ Id = "nubkin", Tier = 1, Hatched = true, Item = "10", HatchAt = 55 },
		} })
		local after = os.time()
		local rows = {}
		for _, row in ipairs(loaded.Held) do
			rows[row.Item] = row
		end
		local grow2 = SeedData.GrowSecondsFor(SeedData.Get("nubkin"), 2)
		local grow3 = SeedData.GrowSecondsFor(SeedData.Get("petalpip"), 3)
		check(rows["7"] ~= nil and rows["7"].HatchAt >= before + grow2 and rows["7"].HatchAt <= after + grow2,
			"a Bag pod saved before deadlines starts its wait at this load: now plus its grow time",
			rows["7"] and rows["7"].HatchAt)
		check(rows["8"] ~= nil and rows["8"].HatchAt == 123, "a saved deadline is kept as it is: long past, so ready")
		check(rows["9"] ~= nil and rows["9"].HatchAt <= after + grow3,
			"and never further off than one whole wait from now", rows["9"] and rows["9"].HatchAt)
		check(rows["10"] ~= nil and rows["10"].HatchAt == nil, "a plant's row carries no deadline")
	end

	--==========================================================================
	say("\n-- 3. two rooms --")
	--==========================================================================
	do
		local plants = {}
		for i = 1, MAX_HELD do
			table.insert(plants, plantRow("nubkin", 1, "p" .. i))
		end
		local p, _, profile = arrive("Rooms", 90000000101, {}, plants)
		local room, count = CarryService.HeldRoom(p)
		local podRoom, pods = CarryService.PodRoom(p)
		check(room == 0 and count == MAX_HELD and podRoom == MAX_PODS and pods == 0,
			"24 plants fill the plants' room and leave the pods' empty",
			string.format("%d/%d plants, %d/%d pods", count, room, pods, podRoom))
		local given = CarryService.GivePod(p, "petalpip", 2)
		task.wait()
		local tool = podTool(p, "petalpip", 2)
		local row = nil
		for _, r in ipairs(profile.Held) do
			if r.Id == "petalpip" and r.Hatched == false then
				row = r
			end
		end
		local grow = SeedData.GrowSecondsFor(SeedData.Get("petalpip"), 2)
		check(given == true and tool ~= nil and row ~= nil and math.abs(row.HatchAt - (os.time() + grow)) <= 2
				and tool:GetAttribute(BAG.Attribute) == row.HatchAt,
			"so a pod is still given, and its wait starts now: its row and its Tool carry one deadline",
			row and row.HatchAt)
	end
	do
		local pods = {}
		for i = 1, MAX_PODS do
			table.insert(pods, podRow("nubkin", 1, "q" .. i, 3600))
		end
		local p, _, profile = arrive("SixtyPods", 90000000102, {}, pods)
		local podRoom, count = CarryService.PodRoom(p)
		local before = #profile.Held
		local given = CarryService.GivePod(p, "petalpip", 2)
		task.wait()
		local room = CarryService.HeldRoom(p)
		check(podRoom == 0 and count == MAX_PODS and given == false and #profile.Held == before
				and #podTools(p) == MAX_PODS and room == MAX_HELD,
			"60 pods fill the pods' room: a pod given is refused and nothing is added; the plants' room is untouched",
			string.format("%d/%d, given %s", count, podRoom, tostring(given)))
	end

	--==========================================================================
	say("\n-- 4. a pod goes in a bed again, with the time it has left --")
	--==========================================================================
	-- 2026-10-10 (the owner: "make the pods placeable on plots again"): placed
	-- as before 10-09, but with its Bag row's HatchAt -- the wait that started
	-- when it was banked -- never a fresh one. The Tool and its row go.
	do
		local p, plot, profile = arrive("Placer", 90000000103, {}, {
			podRow("nubkin", 1, "r1", -10),
			podRow("petalpip", 2, "r2", 600),
		})
		local soil = plot:FindFirstChild(GameConfig.Plot.PlanterName, true)
		local click = if soil then soil.Position else plot:GetPivot().Position
		local function plantItem(item)
			local tool = toolOfItem(p, item)
			local due = rowOfItem(profile, item) and rowOfItem(profile, item).HatchAt
			if tool then
				tool.Parent = p.Character
			end
			local placed, code = PlantService.PlaceAt(p, click)
			task.wait()
			-- The garden held nothing else: its rows are the pods put in it.
			local entry = nil
			for _, row in ipairs(profile.Plants) do
				if row.SpeciesId == (if item == "r1" then "nubkin" else "petalpip") then
					entry = row
				end
			end
			return tool, due, placed, code, entry
		end
		local tool1, due1, placed1, code1, row1 = plantItem("r1")
		check(tool1 ~= nil and placed1 == true and code1 == nil and tool1.Parent == nil and rowOfItem(profile, "r1") == nil
				and row1 ~= nil and row1.HatchAt == due1,
			"a READY pod goes in the bed: its Tool and row are gone, and it keeps its deadline (ready now)",
			tostring(code1) .. " " .. tostring(row1 and row1.HatchAt) .. " vs " .. tostring(due1))
		local tool2, due2, placed2, code2, row2 = plantItem("r2")
		check(tool2 ~= nil and placed2 == true and code2 == nil and row2 ~= nil and row2.HatchAt == due2
				and due2 ~= nil and due2 > os.time() + 500,
			"a growing pod goes in too, with the time it had left in the Bag -- never a fresh wait",
			tostring(code2) .. " " .. tostring(row2 and row2.HatchAt) .. " vs " .. tostring(due2))
	end

	--==========================================================================
	say("\n-- 5. HATCH: one pod, from the Bag --")
	--==========================================================================
	do
		local p, plot, profile = arrive("Hatcher", 90000000104, {}, {
			podRow("nubkin", 2, "h1", 600),
			podRow("petalpip", 3, "h2", -5),
		})
		local n = #reveals
		local ok, code = PlantService.HatchFromBag(p, "h1")
		check(ok == false and code == "NOT_READY" and toolOfItem(p, "h1") ~= nil and #profile.Held == 2
				and #reveals == n,
			"a pod still growing is not hatched: nothing changes", code)
		ok, code = PlantService.HatchFromBag(p, "h2")
		local payload = reveals[n + 1]
		local planted = gardenRowOf(profile, "petalpip", 3)
		check(ok == true and code == "PLANTED", "a ready pod hatches, and with a bed free its plant goes into it", code)
		check(toolOfItem(p, "h2") == nil and rowOfItem(profile, "h2") == nil and #profile.Held == 1,
			"the pod has left the Bag: its Tool and its row, together")
		check(planted ~= nil and planted.Stage == 3 and type(planted.Item) == "string" and #grownTools(p) == 0,
			"the plant is in the garden, grown, saved, an item of its own -- not in the Bag")
		check(payload ~= nil and payload.species == "petalpip" and payload.tier == 3 and payload.owner == p
				and payload.paid == false and typeof(payload.cf) == "CFrame"
				and (payload.cf.Position - plot:GetPivot().Position).Magnitude < 80,
			"the hatch moment is announced once, at the bed it went into: the player is at home")
		check(profile.Almanac.petalpip == true and logged(p, "hatch") and logged(p, "place"),
			"the Almanac learns it, and the guide records the hatch and the place")
		check(grownModelsIn(plot) == 0, "the plant does not stand in its bed while its reveal plays there")
		task.wait(STANDS_UP + 0.6)
		check(grownModelsIn(plot) == 1, "it stands up as the reveal's label fades", grownModelsIn(plot))
		-- Where the reveal stood is where the plant stands: its bed, not beside
		-- the player.
		local standing = nil
		for _, d in ipairs(plot:GetDescendants()) do
			if d:IsA("Model") and d:GetAttribute("PlacementId") ~= nil and d:GetAttribute("Stage") == 3 then
				standing = d
			end
		end
		local gap = if standing and payload
			then (Vector3.new(standing:GetPivot().Position.X, 0, standing:GetPivot().Position.Z)
				- Vector3.new(payload.cf.Position.X, 0, payload.cf.Position.Z)).Magnitude
			else nil
		check(gap ~= nil and gap < 0.5, "and it stands exactly where its reveal played", gap)
	end
	do
		local far = CFrame.new(2000, 2000, 2000)
		local p, _, profile = arrive("Traveller", 90000000105, {}, { podRow("nubkin", 1, "t1", -5) }, far)
		local n = #reveals
		local ok, code = PlantService.HatchFromBag(p, "t1")
		local payload = reveals[n + 1]
		local root = p.Character:FindFirstChild("HumanoidRootPart")
		local flat = if payload and root
			then Vector3.new(payload.cf.Position.X - root.Position.X, 0, payload.cf.Position.Z - root.Position.Z).Magnitude
			else nil
		check(ok == true and code == "PLANTED" and flat ~= nil
				and math.abs(flat - (BAG.FrontStuds + SeedData.PodDiameter(1))) < 0.5
				and gardenRowOf(profile, "nubkin", 1) ~= nil,
			"away from home the moment plays in front of the player, and the plant still goes into a bed", flat)
	end
	do
		local p, _, profile = arrive("FullGarden", 90000000106, grownGarden(CAP), { podRow("spiretip", 2, "f1", -5) })
		local ok, code = PlantService.HatchFromBag(p, "f1")
		task.wait()
		check(ok == true and code == "BAGGED" and toolOfItem(p, "f1") == nil and #grownTools(p) == 1
				and #profile.Plants == CAP and plantRows(profile) == 1,
			"with every bed taken the plant goes into the Bag: a hatched Tool and its row, the garden as it was",
			code)
	end
	do
		local held = { podRow("spiretip", 2, "x1", -5) }
		for i = 1, MAX_HELD do
			table.insert(held, plantRow("nubkin", 1, "xp" .. i))
		end
		local p, _, profile = arrive("NoRoomAtAll", 90000000107, grownGarden(CAP), held)
		local n = #reveals
		local ok, code = PlantService.HatchFromBag(p, "x1")
		check(ok == false and code == "STORAGE_FULL" and toolOfItem(p, "x1") ~= nil and rowOfItem(profile, "x1") ~= nil
				and #reveals == n and saidTo(p, "STORAGE_FULL") == 1,
			"no free bed and 24 plants: refused, the pod stays in the Bag, ready, and the player is told why", code)
	end

	--==========================================================================
	say("\n-- 6. HATCH ALL --")
	--==========================================================================
	do
		local p, _, profile = arrive("AllAtOnce", 90000000108, grownGarden(CAP - 2), {
			podRow("nubkin", 1, "a1", -40),
			podRow("petalpip", 2, "a2", -30),
			podRow("spiretip", 1, "a3", -20),
			podRow("dunebud", 1, "a4", -10),
			podRow("nubkin", 3, "a5", 900),
		})
		local n = #reveals
		local ok, code, planted, bagged, left = PlantService.HatchAllFromBag(p)
		check(ok == true and code == "HATCHED" and planted == 2 and bagged == 2 and left == 0,
			"every ready pod hatches: two into the two free beds, two into the Bag",
			string.format("%s %s %s/%s/%s", tostring(ok), tostring(code), tostring(planted), tostring(bagged),
				tostring(left)))
		check(toolOfItem(p, "a5") ~= nil and rowOfItem(profile, "a5") ~= nil and #podTools(p) == 1
				and #grownTools(p) == 2 and #profile.Plants == CAP,
			"the pod still growing stays in the Bag, growing; the garden is full")
		check(#reveals == n + 1 and reveals[n + 1].species == "nubkin" and reveals[n + 1].tier == 1,
			"the first moment plays at once, the pod that was due first", #reveals - n)
		task.wait(BAG.AllGapSeconds * 3 + 0.4)
		local ats = {}
		for i = n + 1, #reveals do
			table.insert(ats, reveals[i].at)
		end
		local spaced = #ats == 4
		for i = 2, #ats do
			if math.abs((ats[i] - ats[i - 1]) - BAG.AllGapSeconds) > 0.15 then
				spaced = false
			end
		end
		check(spaced, "and the others follow, AllGapSeconds apart", #ats)
	end

	--==========================================================================
	say("\n-- 7. Instant Hatch on a growing Bag pod --")
	--==========================================================================
	do
		local p, _, profile = arrive("InstantBuyer", 90000000109, {}, {
			podRow("nubkin", 4, "i1", -5),
			podRow("petalpip", 5, "i2", 900),
			podRow("spiretip", 6, "i3", 2000),
		})
		local opened = #dialogs
		local ok, code = PlantService.OfferInstantHatchBag(p, "i1")
		check(ok == false and code == "READY" and #dialogs == opened,
			"a ready pod is sold nothing: it hatches free", code)
		profile.InstantCredits = 1
		local n = #reveals
		ok, code = PlantService.OfferInstantHatchBag(p, "i2")
		check(ok == true and code == "CREDIT" and profile.InstantCredits == 0 and #dialogs == opened
				and reveals[n + 1] ~= nil and reveals[n + 1].paid == true and reveals[n + 1].species == "petalpip"
				and rowOfItem(profile, "i2") == nil,
			"with a saved Instant Hatch the press hatches that pod now: the credit spent, no dialog, the paid moment",
			code)
		ok, code = PlantService.OfferInstantHatchBag(p, "i3")
		check(ok == true and code == "OFFERED" and #dialogs == opened + 1 and dialogs[#dialogs].product == SPEC_PRODUCT
				and dialogs[#dialogs].who == p,
			"without one, the press opens the Instant Hatch purchase: the bed prompt's own product", code)
		n = #reveals
		local granted = PlantService.InstantHatch(p)
		check(granted == true and reveals[n + 1] ~= nil and reveals[n + 1].paid == true
				and reveals[n + 1].species == "spiretip" and rowOfItem(profile, "i3") == nil
				and rowOfItem(profile, "i1") ~= nil,
			"the receipt hatches the pod that was pressed, and no other")
	end
	do
		local held = { podRow("dunebud", 2, "j1", 900) }
		for i = 1, MAX_HELD - 1 do
			table.insert(held, plantRow("nubkin", 1, "jp" .. i))
		end
		local p, _, profile = arrive("RoomGoes", 90000000110, grownGarden(CAP), held)
		local opened = #dialogs
		local ok, code = PlantService.OfferInstantHatchBag(p, "j1")
		check(ok == true and code == "OFFERED" and #dialogs == opened + 1,
			"with room for one more plant in the Bag, the dialog opens", code)
		CarryService.GiveHatched(p, SeedData.Get("spiretip"), 1, -1, nil, true)
		local n = #reveals
		local granted = PlantService.InstantHatch(p)
		local row = rowOfItem(profile, "j1")
		local tool = toolOfItem(p, "j1")
		check(granted == true and #reveals == n and row ~= nil and row.HatchAt <= os.time() and tool ~= nil
				and tool:GetAttribute(BAG.Attribute) == row.HatchAt and saidTo(p, "STORAGE_FULL_READY") == 1,
			"the room went before the receipt: the pod is made READY instead, its row and its Tool, and the player is told")
		local again, againCode = PlantService.OfferInstantHatchBag(p, "j1")
		check(again == false and againCode == "READY", "and a ready pod is offered nothing more", againCode)
	end
	do
		local held = { podRow("dunebud", 2, "k1", 900) }
		for i = 1, MAX_HELD do
			table.insert(held, plantRow("nubkin", 1, "kp" .. i))
		end
		local p = arrive("NoRoomNoDialog", 90000000111, grownGarden(CAP), held)
		local opened = #dialogs
		local ok, code = PlantService.OfferInstantHatchBag(p, "k1")
		check(ok == false and code == "STORAGE_FULL" and #dialogs == opened,
			"no free bed and 24 plants: no purchase is opened for a hatch the game would refuse", code)
	end

	--==========================================================================
	say("\n-- 8. an old save's planted pods hatch where they stand --")
	--==========================================================================
	do
		local stamp = os.time()
		local garden = { { SpeciesId = "toadcap", Tier = 2, PlantedAt = stamp - 500, HatchAt = stamp - 10,
			X = -6, Z = -4, Stage = 1, Facing = 0 } }
		local p, plot, profile = arrive("OldGarden", 90000000112, garden, {})
		local ok, why = PlantService.HatchByHand(p, plot, 1)
		check(ok == true and why == nil and #grownTools(p) == 1 and #profile.Plants == 0,
			"a pod planted before the change hatches by hand, exactly as before: the plant into the Bag, the bed free",
			tostring(ok))
	end

	--==========================================================================
	say("\n-- 9. a death --")
	--==========================================================================
	do
		local p, _, profile = arrive("Respawns", 90000000113, {}, {
			podRow("nubkin", 1, "d1", 300),
			podRow("petalpip", 2, "d2", 700),
		})
		local due1, due2 = rowOfItem(profile, "d1").HatchAt, rowOfItem(profile, "d2").HatchAt
		die(p)
		local t1, t2 = toolOfItem(p, "d1"), toolOfItem(p, "d2")
		check(t1 ~= nil and t2 ~= nil and t1:GetAttribute(BAG.Attribute) == due1
				and t2:GetAttribute(BAG.Attribute) == due2 and rowOfItem(profile, "d1").HatchAt == due1,
			"after a death every pod is rebuilt wearing its own saved deadline: no wait starts over")
	end

	--==========================================================================
	say("\n-- 10. EQUIP BEST counts the plants' room only --")
	--==========================================================================
	do
		-- 23 better plants and 30 pods in the Bag: under the old shared room of
		-- 24 the swap would have been refused for room.
		local held = {}
		for i = 1, 30 do
			table.insert(held, podRow("nubkin", 1, "e" .. i, 3600))
		end
		for i = 1, MAX_HELD - 1 do
			table.insert(held, plantRow("nubkin", 3, "ep" .. i))
		end
		local p = arrive("EquipsBest", 90000000114, grownGarden(CAP), held)
		local ok, code, inCount, outCount = PlantService.EquipBest(p)
		check(ok == true and code == "EQUIPPED" and inCount == CAP and outCount == CAP,
			"a swap that fits the plants' room is made, whatever pods the Bag holds",
			string.format("%s %s %s/%s", tostring(ok), tostring(code), tostring(inCount), tostring(outCount)))
	end
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

if PlantService then
	pcall(PlantService.usePrompt, nil)
	pcall(PlantService.Init)
end
if CarryService then
	pcall(CarryService.Init)
end
ActionRefusal.capture(nil)
for name, fn in pairs(real) do
	PlayerDataService[name] = fn
end
for _, plot in ipairs(plots) do
	plot:Destroy()
end
fixture:Destroy()
local shells = Workspace:FindFirstChild("SeedBagHatchShells")
if shells then
	shells:Destroy()
end

say(string.format("\nHatchInBagSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
