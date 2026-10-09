--!nocheck
--==============================================================================
-- Steal a Seed :: StorageDoorsSpec
--
-- PLANT STORAGE FULL, THE OTHER DOORS (2026-09-29). Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("StorageDoorsSpec"))
--
-- The saved record holds GameConfig.Save.MaxHeld plants and pods. A hatch past
-- it is refused (HatchStorageSpec). Two other doors handed something over past
-- it that was never written down -- gone at the next death or rejoin:
--
--   PICK UP      a grown plant left the garden for a bag that did not record it
--   THE RED LINE a raided pod was banked into a bag that did not record it
--
-- The owner's rule for both:
--
--   "picking up a grown plant and banking a pod at 24/24 must not hand over an
--    item that cannot be saved. Preserve the item in its prior safe state and
--    give a clear, non-spamming storage-full message. Do not truncate existing
--    over-cap records."
--
-- So the plant stays planted, and the pod stays where it was: at the nest if
-- the record was full when it was reached for (the take is refused, because a
-- pod refused at the line would be one its carrier can neither bank nor put
-- down), and in the arms if the record filled on the run home.
--
-- And the pod-grant doors (2026-09-30), from the owner's brief: "Ordinary
-- player actions must respect storage capacity without losing or duplicating
-- a pod. Preserve the beginner tutorial's ability to recover ... Do not
-- acknowledge any paid pod receipt without either a durable pod grant or a
-- durable owed reward." A pod given (the wheel's prize, a paid pod), a paid pod
-- through the real StoreService, and the beginner's reserved pod: 8b to 8d.
--
-- THE REAL PlantService, THE REAL CarryService AND THE REAL StoreService, each
-- loaded from its source. What stands in is what a spec cannot have:
-- PlotService, the profile store (with writes that can be made to fail),
-- MarketplaceService, NestService (a list of what it was asked), Metrics, the
-- Players service and the players -- tables whose signals are real and whose
-- Backpack and body are real instances, destroyed the way the engine destroys
-- them. The clock the two services read can be moved forward, so that a quiet
-- time of thirty seconds is not thirty seconds of waiting.
--
-- The bank is CarryService.Bank, the function the red line's poll calls: a
-- stand-in player cannot be stood on the line. That the poll calls it, and only
-- inside the Safe Zone, is Play's to show.
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
local TutorialData = require(Shared:WaitForChild("TutorialData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PlayerDataService = require(Server:WaitForChild("PlayerDataService"))
local PlantWander = require(Server:WaitForChild("PlantWander"))
local MapService = require(Server:WaitForChild("MapService"))

local HATCH = GameConfig.Plant.Hatch
local ROLL = HATCH.Roll
local ATTR = GameConfig.Attributes
local KG = ATTR.CarryingKg
local MAX = GameConfig.Save.MaxHeld
local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
local RETRY = Enum.ProductPurchaseDecision.NotProcessedYet

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

-- What a script says, for the checks that read it: PLAIN FINDS only.
local function sourceOf(instance)
	if instance == nil then
		return nil
	end
	local ok, src = pcall(function()
		return (instance :: any).Source
	end)
	return if ok then src else nil
end

--==============================================================================
-- LOADING A MODULE WITH SOMETHING ELSE IN ITS HANDS
--==============================================================================
local outerRequire = require
local function loadWith(module, siblings, overrides, gameStandIn, extras)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	local env = {
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
	}
	for name, value in pairs(extras or {}) do
		env[name] = value
	end
	setfenv(chunk, setmetatable(env, { __index = getfenv(1) }))
	return chunk()
end

-- The manifest with a made-up Instant Hatch id, the roll off as it ships, and
-- always day: a pod is not taken at night, and the time of day is not this
-- spec's.
local SPEC_PRODUCT = 990078
-- A paid pod on sale for this spec alone. The manifest's three pod products all
-- have an id of 0, which is what keeps them off sale: no purchase can be
-- opened for them and no receipt can name one.
local SPEC_POD_PRODUCT = 990079
local function configFor()
	local rollConfig = setmetatable({ Enabled = false, StudioPreview = false }, { __index = ROLL })
	local hatchConfig = setmetatable({ Roll = rollConfig }, { __index = HATCH })
	local plantConfig = setmetatable({ Hatch = hatchConfig }, { __index = GameConfig.Plant })
	local hatchItem = { key = "instanthatch", kind = "hatch", robux = 99, product = SPEC_PRODUCT }
	for _, item in ipairs(GameConfig.Store.InWorld or {}) do
		if item.kind == "hatch" then
			hatchItem = table.clone(item)
			hatchItem.product = SPEC_PRODUCT
		end
	end
	local podItem = { key = "specpod", kind = "pod", robux = 79, product = SPEC_POD_PRODUCT,
		species = "bellchime", tier = 3 }
	return setmetatable({
		Plant = plantConfig,
		-- THE POD ROOM AT THE PLANTS' 24 IN THIS SPEC (2026-10-09), so its fixtures
		-- stay small: the doors are the same at any limit, and the real 60 is
		-- HatchInBagSpec's.
		Save = setmetatable({ MaxPods = GameConfig.Save.MaxHeld }, { __index = GameConfig.Save }),
		Store = setmetatable({ InWorld = { hatchItem, podItem } }, { __index = GameConfig.Store }),
		isDay = function()
			return true
		end,
	}, { __index = GameConfig })
end

--==============================================================================
-- THE PLAYERS, AND THE SERVICE THEY ARE IN
--==============================================================================
local leaving = {}
local present = {}
local Players = {
	PlayerRemoving = {
		Connect = function(_, fn)
			table.insert(leaving, fn)
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
function Players:GetPlayerByUserId(id)
	local p = present[id]
	return if p and p.Parent == Players then p else nil
end

local fixture = Instance.new("Folder")
fixture.Name = "StorageDoorsSpecFixture"
fixture.Parent = Workspace

-- Where every carrier stands, on a floor of their own: a dropped pod is put on
-- the ground under the carrier, and with none it would land on the map below.
local ORIGIN = Vector3.new(60, 2700, 60)
local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Anchored = true
floor.Size = Vector3.new(60, 1, 60)
floor.CFrame = CFrame.new(ORIGIN - Vector3.new(0, 0.5, 0))
floor.Parent = fixture
local map = Workspace:FindFirstChild(GameConfig.Map.FolderName)
local mapBefore = {}
if map then
	for _, d in ipairs(map:GetChildren()) do
		mapBefore[d] = true
	end
end

local function living(name, userId, carrier)
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
		_carrier = carrier == true,
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

-- A carrier has the Head and the root a take asks for (CarryHandsSpec's), and
-- is given its Humanoid for the length of the take (see take): a Humanoid in
-- Edit equips every plant it is handed, and a body that belongs to no Player
-- has no Backpack for the one before to go back to. Everybody else has
-- HatchStorageSpec's bare body.
local function newBody(p, announce)
	local body = Instance.new("Model")
	body.Name = p.Name .. "Body"
	if p._carrier then
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 2, 1)
		root.Anchored = true
		root.CanCollide = false
		root.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 3, 0))
		root.Parent = body
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1, 1, 1)
		head.Anchored = true
		head.CanCollide = false
		head.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 4.5, 0))
		head.Parent = body
		body.PrimaryPart = root
	end
	body.Parent = fixture
	p.Character = body
	if announce then
		p._fire.characterAdded:Fire(body)
	end
	return body
end

-- Every plant or pod Tool this player has, in the bag and in the hands.
local function plantsOf(p)
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

-- The raided pod welded to this body, if there is one.
local function inArms(p)
	local body = p.Character
	if body and body.Parent then
		for _, d in ipairs(body:GetChildren()) do
			if d:IsA("Model") and CollectionService:HasTag(d, GameConfig.Tags.CarriedPod) then
				return d
			end
		end
	end
	return nil
end

local function keyOf(id, tier, hatched)
	return string.format("%s:%d:%s", tostring(id), math.floor(tonumber(tier) or 0), tostring(hatched == true))
end

local function census(list, read)
	local counts, names = {}, {}
	for _, item in ipairs(list) do
		local key = read(item)
		if counts[key] == nil then
			counts[key] = 0
			table.insert(names, key)
		end
		counts[key] += 1
	end
	table.sort(names)
	for i, key in ipairs(names) do
		names[i] = string.format("%s x%d", key, counts[key])
	end
	return table.concat(names, ", ")
end

local function toolKey(tool)
	return keyOf(tool:GetAttribute("SpeciesId"), tool:GetAttribute(KG), tool:GetAttribute("Hatched"))
end

local function rowKey(row)
	return keyOf(row.Id, row.Tier, row.Hatched)
end

local function countKey(list, read, key)
	local n = 0
	for _, item in ipairs(list) do
		if read(item) == key then
			n += 1
		end
	end
	return n
end

-- A record of `n` rows, all of them one tier, so that anything of two tiers or
-- more is the thing a check is about. Since 2026-10-09 pods and plants have
-- rooms of their own: `rowsOf` fills the PLANT room (pickups, hatches) and
-- `podRowsOf` the POD room (takes, banks, pods given), each pod with a deadline.
local POOL = { "nubkin", "petalpip", "spiretip", "dunebud" }
local function rowsOf(n)
	local rows = {}
	for i = 1, n do
		table.insert(rows, { Id = POOL[(i % #POOL) + 1], Tier = 1, Hatched = true })
	end
	return rows
end
local function podRowsOf(n)
	local rows = {}
	for i = 1, n do
		table.insert(rows, { Id = POOL[(i % #POOL) + 1], Tier = 1, Hatched = false, HatchAt = os.time() + 3600 })
	end
	return rows
end

--==============================================================================
-- THE PROFILE STORE
--==============================================================================
local real = {
	IsReady = PlayerDataService.IsReady,
	Get = PlayerDataService.Get,
	SetHeld = PlayerDataService.SetHeld,
	SetPlants = PlayerDataService.SetPlants,
	MarkSeen = PlayerDataService.MarkSeen,
	RecordTutorial = PlayerDataService.RecordTutorial,
	Save = PlayerDataService.Save,
}
local ready = {}
local profiles = {}
local heldFails = {}
local writes = {}
local tutorials = {}

PlayerDataService.IsReady = function(p)
	return ready[p] == true
end
PlayerDataService.Get = function(p)
	return if ready[p] then profiles[p] else nil
end
PlayerDataService.SetHeld = function(p, rows)
	if not profiles[p] or not ready[p] or type(rows) ~= "table" or heldFails[p] then
		return false
	end
	profiles[p].Held = rows
	table.insert(writes, { who = p.Name, list = "Held", rows = #rows })
	return true
end
PlayerDataService.SetPlants = function(p, rows)
	if not profiles[p] or type(rows) ~= "table" then
		return false
	end
	profiles[p].Plants = rows
	table.insert(writes, { who = p.Name, list = "Plants", rows = #rows,
		heldThen = #profiles[p].Held, toolsThen = #plantsOf(p) })
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
	table.insert(tutorials, { who = p.Name, step = step })
end
-- A save that does not reach the disk, and what each save held when it was asked
-- for: the rows, and the ledger of honoured purchases.
local saveFails = {}
local saves = {}
PlayerDataService.Save = function(p)
	local profile = profiles[p]
	table.insert(saves, { who = p.Name, worked = not saveFails[p], held = profile and #profile.Held or -1,
		receipts = if profile and profile.Receipts then table.clone(profile.Receipts) else {} })
	return not saveFails[p]
end

local function lastSave(name)
	for i = #saves, 1, -1 do
		if saves[i].who == name then
			return saves[i]
		end
	end
	return nil
end

-- Every row of the record: plants only, so a pod row is the thing a check is about.
local function plantRows(n)
	local rows = {}
	for i = 1, n do
		table.insert(rows, { Id = POOL[(i % #POOL) + 1], Tier = 1, Hatched = true })
	end
	return rows
end

local function writesOf(name, list)
	local n = 0
	for _, w in ipairs(writes) do
		if w.who == name and w.list == list then
			n += 1
		end
	end
	return n
end

local function lastGardenWrite(name)
	for i = #writes, 1, -1 do
		if writes[i].who == name and writes[i].list == "Plants" then
			return writes[i]
		end
	end
	return nil
end

local function stepsOf(name, step)
	local n = 0
	for _, t in ipairs(tutorials) do
		if t.who == name and t.step == step then
			n += 1
		end
	end
	return n
end

local function plantRow(profile, speciesId, tier)
	for _, row in ipairs(profile.Plants) do
		if row.SpeciesId == speciesId and row.Tier == tier then
			return row
		end
	end
	return nil
end

--==============================================================================
-- WHAT THE GAME SAYS TO A PLAYER
--==============================================================================
local said = {}
ActionRefusal.capture(function(player, code)
	table.insert(said, { who = player.Name, code = code })
end)
local function saidTo(name, code)
	local n = 0
	for _, line in ipairs(said) do
		if line.who == name and (code == nil or line.code == code) then
			n += 1
		end
	end
	return n
end

--==============================================================================
-- A WORLD: ONE CarryService, ONE PlantService AND ONE StoreService
--==============================================================================
local worlds = {}
local plots = {}

local function newPlot(plotOf, ownerOf)
	local index = #plots + 1
	local plot = Instance.new("Model")
	plot.Name = "StorageDoorsSpecPlot" .. index
	plot.Archivable = false
	plot:SetAttribute("PreviewOnly", true)
	plot:SetAttribute(ATTR.PlotId, 500 + index)
	plot.Parent = Workspace
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	local y = 3200 + index * 60
	plot:SetAttribute("PlotCF", CFrame.lookAt(Vector3.new(0, y, centreR), Vector3.new(0, y, 0)))
	plot:SetAttribute("Depth", startDepth)
	MapService.ResizePlot(plot, 1)
	table.insert(plots, plot)
	return plot
end

local function modelFor(plot, id)
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("PlacementId") == id
			and CollectionService:HasTag(d, GameConfig.Tags.Planted) then
			return d
		end
	end
	return nil
end

local function promptsOn(model, name)
	local n = 0
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.Name == name then
				n += 1
			end
		end
	end
	return n
end

local function plantedIn(plot)
	local n = 0
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("PlacementId") ~= nil
			and CollectionService:HasTag(d, GameConfig.Tags.Planted) then
			n += 1
		end
	end
	return n
end

-- A garden is put back in the order its rows were saved in, so a plant may come
-- back under another placement id. The day it was planted is its own.
local function idPlantedAt(plot, plantedAt)
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("PlacementId") ~= nil
			and CollectionService:HasTag(d, GameConfig.Tags.Planted)
			and d:GetAttribute("PlantedAt") == plantedAt then
			return d:GetAttribute("PlacementId")
		end
	end
	return nil
end

-- Plants and pods in the order given, which is the order their placement ids
-- are handed out in. Each is planted a second apart, so that each can be told
-- from the others after a rejoin.
local function gardenOf(planted)
	local rows = {}
	local now = os.time()
	for i, item in ipairs(planted) do
		table.insert(rows, {
			SpeciesId = item.id,
			Tier = item.tier,
			PlantedAt = now - 5000 - i,
			HatchAt = if item.grown or item.ready then now - 60 - i else now + (item.wait or (9000 - i * 100)),
			X = -12 + i * 3,
			Z = -4,
			Stage = if item.grown then 3 else 1,
			Facing = 0,
		})
	end
	return rows
end

local function makeWorld()
	local w = { reveals = {}, prompts = {}, receipt = nil, nest = {}, metrics = {}, skew = 0 }
	local config = configFor()

	local fakeMarket = setmetatable({}, {
		__newindex = function(t, key, value)
			if key == "ProcessReceipt" then
				w.receipt = value
			else
				rawset(t, key, value)
			end
		end,
	})
	rawset(fakeMarket, "PromptProductPurchase", function(_, player, productId)
		table.insert(w.prompts, { who = player.Name, product = productId })
	end)
	local fakeGame = {}
	function fakeGame:GetService(name)
		if name == "MarketplaceService" then
			return fakeMarket
		elseif name == "Players" then
			return Players
		end
		return game:GetService(name)
	end

	-- The clock both services read, which can be moved forward.
	local clock = setmetatable({
		clock = function()
			return os.clock() + w.skew
		end,
	}, { __index = os })
	function w.later(seconds)
		w.skew += seconds
	end

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

	-- A nest that writes down what it was asked, and gives up its pod.
	local NestService = {
		TakePod = function(pod, player)
			table.insert(w.nest, { call = "TakePod", who = player.Name })
			local species = SeedData.Get(pod:GetAttribute("SpeciesId") or "")
			pod:Destroy()
			return species
		end,
		Provoke = function(nestId, player)
			table.insert(w.nest, { call = "Provoke", who = player.Name, nest = nestId })
		end,
		SetCarryBridge = function() end,
	}
	local Metrics = setmetatable({}, {
		__index = function(_, name)
			return function(player, what)
				table.insert(w.metrics, { call = name,
					who = if type(player) == "table" then player.Name else tostring(player), what = what })
			end
		end,
	})

	w.HatchRoll = loadWith(Shared.HatchRoll, { GameConfig = config, SeedData = SeedData })
	w.CarryService = loadWith(Server.CarryService, {
		NestService = NestService,
		MapService = MapService,
		PlayerDataService = PlayerDataService,
		Metrics = Metrics,
		GuardianCatch = require(Server:WaitForChild("GuardianCatch")),
		CarryGuard = require(Server:WaitForChild("CarryGuard")),
	}, { GameConfig = config }, fakeGame, { os = clock })
	w.PlantService = loadWith(Server.PlantService, {
		PlotService = PlotService,
		PlayerDataService = PlayerDataService,
		CarryService = w.CarryService,
		PlantWander = PlantWander,
		GardenFrame = require(Server:WaitForChild("GardenFrame")),
	}, { GameConfig = config, HatchRoll = w.HatchRoll }, fakeGame, { os = clock })
	w.PlantService.Init()
	w.PlantService.Start()
	w.PlantService.OnRevealed(function(payload)
		table.insert(w.reveals, payload)
	end)
	w.StoreService = loadWith(Server.StoreService, {
		PlayerDataService = PlayerDataService,
		CarryService = w.CarryService,
		TreadmillService = {
			PayReward = function()
				return true
			end,
		},
		PlantService = w.PlantService,
		WheelService = {
			GrantBought = function()
				return false
			end,
		},
	}, { GameConfig = config }, fakeGame)
	w.StoreService.Init()
	w.StoreService.Start()

	-- Here, armed, with a garden. Returns the player, their plot and their profile.
	function w.arrive(name, userId, planted, held, profile, carrier)
		local p = living(name, userId, carrier)
		profile = profile or { Plants = gardenOf(planted or {}), Held = held or {}, Almanac = {},
			Receipts = {}, Speed = 0 }
		profiles[p] = profile
		ready[p] = true
		present[userId] = p
		newBackpack(p, false)
		newBody(p, false)
		w.CarryService.WatchHeld(p)
		w.CarryService.RestoreHeld(p)
		task.wait(0.4)
		local plot = newPlot(plotOf, ownerOf)
		plotOf[p] = plot
		ownerOf[plot] = p
		assignedFn(p, plot)
		return p, plot, profile
	end

	-- The held prompt on a ready pod, by the name the prompt itself calls.
	function w.byHand(p, plot, id)
		local before = #w.reveals
		local answered, why = w.PlantService.HatchByHand(p, plot, id)
		return answered, why, w.reveals[before + 1]
	end

	-- One delivery of one receipt, through StoreService.
	function w.deliver(p, purchaseId)
		local before = #w.reveals
		local decision = w.receipt({
			PlayerId = p.UserId,
			ProductId = SPEC_PRODUCT,
			PurchaseId = purchaseId,
			CurrencySpent = 99,
		})
		return decision, w.reveals[before + 1]
	end

	-- What a sale does, or a planting: the Tools go, and the transaction takes
	-- their rows off the record (SellService, PlantService.PlaceAt).
	function w.makeRoom(p, n)
		local gone = {}
		for _, tool in ipairs(plantsOf(p)) do
			if #gone < n then
				table.insert(gone, tool)
			end
		end
		for _, tool in ipairs(gone) do
			tool:Destroy()
		end
		w.CarryService.SyncHeldNow(p, gone)
		task.wait()
		return #gone
	end

	-- A pod lying loose within reach of where every carrier stands.
	function w.pod(speciesId, tier, nestId)
		local pod = w.CarryService.SpawnLoose(speciesId, tier,
			CFrame.new(ORIGIN + Vector3.new(0, 0, -2)), nil, nil, true)
		if pod and nestId then
			pod:SetAttribute("NestId", nestId)
		end
		return pod
	end

	-- One delivery of one receipt for the spec's own paid pod, through
	-- StoreService.
	function w.buyPod(p, purchaseId)
		return w.receipt({
			PlayerId = p.UserId,
			ProductId = SPEC_POD_PRODUCT,
			PurchaseId = purchaseId,
			CurrencySpent = 79,
		})
	end

	-- The real TryTake, on a body that is alive for as long as it runs.
	function w.take(p, pod)
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = p.Character
		local ok, took = pcall(w.CarryService.TryTake, p, pod)
		humanoid:Destroy()
		if not ok then
			say("  NOTE  TryTake threw: " .. tostring(took))
			return nil
		end
		return took
	end

	function w.metricsOf(name, call, what)
		local n = 0
		for _, m in ipairs(w.metrics) do
			if m.who == name and m.call == call and (what == nil or m.what == what) then
				n += 1
			end
		end
		return n
	end

	table.insert(worlds, w)
	return w
end

-- A teardown step, followed by the stray syncs that land in a real one.
local function step(w, p, fn)
	fn()
	w.CarryService.SyncHeldNow(p)
	task.wait(0.05)
	w.CarryService.SyncHeldNow(p)
end

-- A death, in the engine's order. A carrier's pod is dropped where they stood
-- first: that is what CarryService's own watcher does when the Humanoid dies,
-- and a Humanoid does not die in Edit.
local function die(w, p)
	local pack, body = p._backpack, p.Character
	local dropped = false
	if w.CarryService.IsCarrying(p) then
		dropped = w.CarryService.Drop(p, ORIGIN + Vector3.new(0, 0, -2))
	end
	step(w, p, function()
		p._fire.characterRemoving:Fire(body)
	end)
	step(w, p, function()
		p.Character = nil
		body:Destroy()
	end)
	step(w, p, function()
		pack:Destroy()
	end)
	local newPack = newBackpack(p, false)
	step(w, p, function()
		p._fire.childAdded:Fire(newPack)
	end)
	local newBodyModel = newBody(p, false)
	step(w, p, function()
		p._fire.characterAdded:Fire(newBodyModel)
	end)
	task.wait(0.8)
	return dropped
end

-- Leaving, in the engine's order: the session ends, then the body and the bag go.
local function leave(w, p)
	local pack, bodyModel = p._backpack, p.Character
	for _, fn in ipairs(leaving) do
		fn(p)
	end
	p.Parent = nil
	step(w, p, function()
		p._fire.characterRemoving:Fire(bodyModel)
	end)
	step(w, p, function()
		p.Character = nil
		bodyModel:Destroy()
	end)
	step(w, p, function()
		pack:Destroy()
	end)
	task.wait(0.3)
	ready[p] = nil
end

-- The loose pods this spec has left lying on the map.
local function looseOnMap()
	local found = {}
	if map then
		for _, d in ipairs(map:GetChildren()) do
			if not mapBefore[d] and d:IsA("Model") and d:GetAttribute("SpeciesId") ~= nil then
				table.insert(found, d)
			end
		end
	end
	return found
end

local function body()
	local loadOk, loadErr = pcall(makeWorld)
	local w = worlds[1]
	check(loadOk and w ~= nil and type(w.receipt) == "function" and type(w.CarryService.Bank) == "function",
		"the real PlantService, CarryService and StoreService load", loadErr)
	if not (loadOk and w and w.receipt) then
		return
	end
	check(MAX == 24 and GameConfig.Save.MaxPods == 60,
		"the saved record holds 24 plants and, in a room of their own, 60 pods (run at 24 here)", MAX)
	check(map ~= nil, "the map folder exists (loose pods lie in it)")
	if not map then
		return
	end

	-- The record's last place taken by something no door counts: a plant handed
	-- back the way a rebuild hands one back (GiveHatched with no onRecord), and
	-- written down by the bag's own snapshot.
	local function fillUncounted(p)
		w.CarryService.GiveHatched(p, SeedData.Get("spiretip"), 1)
		w.CarryService.SyncHeldNow(p)
		task.wait()
	end

	-- THE POD ROOM'S OWN (2026-10-09): one fixture pod sold (a tier-1 one, never a
	-- pod a check is about), and the pod room filled by a pod Tool that arrived a
	-- way no door counts -- as a rebuild puts one back -- and written down by the
	-- bag's own snapshot.
	local function sellOnePod(p)
		for _, tool in ipairs(plantsOf(p)) do
			if tool:GetAttribute("Hatched") ~= true and tool:GetAttribute(KG) == 1 then
				tool:Destroy()
				w.CarryService.SyncHeldNow(p, { tool })
				task.wait()
				return true
			end
		end
		return false
	end
	local function fillPodUncounted(p)
		for _, tool in ipairs(plantsOf(p)) do
			if tool:GetAttribute("Hatched") ~= true and tool:GetAttribute(KG) == 1 then
				local extra = tool:Clone()
				extra:SetAttribute(ATTR.ItemId, nil)
				extra.Parent = p._backpack
				w.CarryService.SyncHeldNow(p)
				task.wait()
				return true
			end
		end
		return false
	end

	-- One PLANT sold, as the stall sells one: never a pod, so the pods a check
	-- counts are not what makes the room.
	local function sellOnePlant(p)
		for _, tool in ipairs(plantsOf(p)) do
			if tool:GetAttribute("Hatched") == true then
				tool:Destroy()
				w.CarryService.SyncHeldNow(p, { tool })
				task.wait()
				return true
			end
		end
		return false
	end

	--==========================================================================
	-- 1. PICK UP, WITH THE RECORD FULL
	--==========================================================================
	say("\n-- pick up: refused at 24 --")
	local p, plot, profile = w.arrive("Picker", -701, {
		{ id = "nubkin", tier = 2, grown = true },
		{ id = "novaorb", tier = 3, grown = true },
		{ id = "bellchime", tier = 1, ready = true },
	}, rowsOf(MAX))
	local firstPlanted = plantRow(profile, "nubkin", 2).PlantedAt
	local secondPlanted = plantRow(profile, "novaorb", 3).PlantedAt
	do
		check(w.CarryService.IsHeldRestored(p) and #plantsOf(p) == MAX and #profile.Held == MAX
				and plantedIn(plot) == 3 and #w.PlantService.GrownIn(plot) == 2,
			"a player with 24 saved has all 24 in the bag, and two grown plants and a pod in the garden",
			string.format("%d tools, %d rows, %d planted", #plantsOf(p), #profile.Held, plantedIn(plot)))
		local toolsBefore, rowsBefore = census(plantsOf(p), toolKey), census(profile.Held, rowKey)
		local gardenBefore, heldBefore = writesOf(p.Name, "Plants"), writesOf(p.Name, "Held")
		local picked, why = w.PlantService.PickUpById(p, 1)
		check(picked == false and why == "STORAGE_FULL", "the pickup is refused, for room",
			tostring(picked) .. " / " .. tostring(why))
		check(#plantsOf(p) == MAX and census(plantsOf(p), toolKey) == toolsBefore,
			"no plant is handed over: the bag is the bag it was", #plantsOf(p))
		check(#profile.Held == MAX and census(profile.Held, rowKey) == rowsBefore
				and writesOf(p.Name, "Held") == heldBefore,
			"the record is the record it was, and was not rewritten", #profile.Held)
		local row = plantRow(profile, "nubkin", 2)
		check(modelFor(plot, 1) ~= nil and plantedIn(plot) == 3 and w.PlantService.CountIn(plot) == 3
				and #w.PlantService.GrownIn(plot) == 2 and #profile.Plants == 3
				and row ~= nil and row.Stage == 3 and writesOf(p.Name, "Plants") == gardenBefore,
			"THE PLANT STAYS PLANTED: standing, grown, counted, and the garden not rewritten",
			string.format("%d planted, %d grown", plantedIn(plot), #w.PlantService.GrownIn(plot)))
		check(saidTo(p.Name, "STORAGE_FULL") == 1 and saidTo(p.Name) == 1,
			"the player is told PLANT STORAGE FULL, once", saidTo(p.Name))

		-- Pressed again and again, on both plants.
		for _ = 1, 4 do
			w.PlantService.PickUpById(p, 1)
			w.PlantService.PickUpById(p, 2)
		end
		check(saidTo(p.Name) == 1 and #plantsOf(p) == MAX and #profile.Held == MAX and plantedIn(plot) == 3
				and census(plantsOf(p), toolKey) == toolsBefore,
			"eight more presses change nothing and say nothing more", saidTo(p.Name))
		w.later(2.1)
		w.PlantService.PickUpById(p, 2)
		check(saidTo(p.Name, "STORAGE_FULL") == 2 and saidTo(p.Name) == 2,
			"a try a few seconds later is answered again: the line is not said once and never after",
			saidTo(p.Name))
		-- A pod is not a thing to pick up, full or not; nor is what is not there.
		local pod, podWhy = w.PlantService.PickUpById(p, 3)
		local nothing, nothingWhy = w.PlantService.PickUpById(p, 99)
		check(pod == false and podWhy == nil and nothing == false and nothingWhy == nil and saidTo(p.Name) == 2,
			"every other refusal is as silent as it was: an unhatched pod, a plant that is not there")
	end

	--==========================================================================
	-- 2. PICK UP: A DEATH, A REJOIN, AND THEN ROOM
	--==========================================================================
	say("\n-- pick up: a death, a rejoin, making room --")
	do
		local rowsBefore = census(profile.Held, rowKey)
		die(w, p)
		check(#plantsOf(p) == MAX and #profile.Held == MAX and census(profile.Held, rowKey) == rowsBefore
				and census(plantsOf(p), toolKey) == rowsBefore,
			"after a refusal and a death the 24 are rebuilt: no plant lost, none made",
			string.format("%d tools, %d rows", #plantsOf(p), #profile.Held))
		check(modelFor(plot, 1) ~= nil and modelFor(plot, 2) ~= nil and plantedIn(plot) == 3
				and #w.PlantService.GrownIn(plot) == 2 and #profile.Plants == 3,
			"and both plants are still planted")
		w.later(2.1)
		local again, againWhy = w.PlantService.PickUpById(p, 1)
		check(again == false and againWhy == "STORAGE_FULL" and #plantsOf(p) == MAX,
			"the new body is refused the same way: the record decides, not the body")

		leave(w, p)
		local left = plantRow(profile, "nubkin", 2)
		check(#profile.Held == MAX and census(profile.Held, rowKey) == rowsBefore and #profile.Plants == 3
				and left ~= nil and left.Stage == 3 and left.PlantedAt == firstPlanted,
			"the save they leave with has the 24 and the plant, still in the garden",
			string.format("%d rows, %d planted", #profile.Held, #profile.Plants))

		local back, backPlot = w.arrive("Picker", -701, nil, nil, profile)
		local firstId = idPlantedAt(backPlot, firstPlanted)
		local secondId = idPlantedAt(backPlot, secondPlanted)
		check(#plantsOf(back) == MAX and #profile.Held == MAX and census(profile.Held, rowKey) == rowsBefore
				and plantedIn(backPlot) == 3 and #w.PlantService.GrownIn(backPlot) == 2
				and firstId ~= nil and secondId ~= nil,
			"they come back to the 24, and to both plants in the garden",
			string.format("%d tools, %d rows, %d planted", #plantsOf(back), #profile.Held, plantedIn(backPlot)))
		local stillNo, stillWhy = w.PlantService.PickUpById(back, firstId or 0)
		check(stillNo == false and stillWhy == "STORAGE_FULL" and saidTo(back.Name, "STORAGE_FULL") >= 1,
			"which are still refused, and the reason said")

		-- One sold or planted.
		check(w.makeRoom(back, 1) == 1 and #plantsOf(back) == MAX - 1 and #profile.Held == MAX - 1,
			"one plant sold or planted: 23 in the bag, 23 on the record")
		local gardenBefore = writesOf(back.Name, "Plants")
		local yes, yesWhy = w.PlantService.PickUpById(back, firstId or 0)
		check(yes == true and yesWhy == nil, "the plant that was refused is picked up",
			tostring(yes) .. " / " .. tostring(yesWhy))
		-- Asked at once, with no frame in between: the row is written in the
		-- call that made the Tool, not by the bag's watcher a moment later.
		check(#plantsOf(back) == MAX and #profile.Held == MAX
				and countKey(profile.Held, rowKey, "nubkin:2:true") == 1
				and countKey(plantsOf(back), toolKey, "nubkin:2:true") == 1
				and census(profile.Held, rowKey) == census(plantsOf(back), toolKey),
			"its Tool is in the bag and its row is on the record at once: 24 of each, the same 24",
			census(profile.Held, rowKey))
		local garden = lastGardenWrite(back.Name)
		check(writesOf(back.Name, "Plants") == gardenBefore + 1 and garden ~= nil and garden.rows == 2
				and garden.heldThen == MAX and modelFor(backPlot, firstId or 0) == nil
				and w.PlantService.CountIn(backPlot) == 2 and plantRow(profile, "nubkin", 2) == nil,
			"the garden is saved without it, and only after the plant was on the record",
			garden and string.format("%d planted, %d rows then", garden.rows, garden.heldThen))
		local next, nextWhy = w.PlantService.PickUpById(back, secondId or 0)
		check(next == false and nextWhy == "STORAGE_FULL" and modelFor(backPlot, secondId or 0) ~= nil
				and #plantsOf(back) == MAX and #profile.Held == MAX,
			"and the record is full again: the other plant stays planted")

		-- What was picked up is still there after a death and a rejoin.
		die(w, back)
		check(#plantsOf(back) == MAX and #profile.Held == MAX
				and countKey(plantsOf(back), toolKey, "nubkin:2:true") == 1,
			"the plant that was picked up is rebuilt after a death, once",
			string.format("%d tools, %d rows", #plantsOf(back), #profile.Held))
		leave(w, back)
		local third = w.arrive("Picker", -701, nil, nil, profile)
		check(#plantsOf(third) == MAX and #profile.Held == MAX
				and countKey(plantsOf(third), toolKey, "nubkin:2:true") == 1 and #profile.Plants == 2,
			"and is in the bag after a rejoin, with the garden one plant smaller",
			string.format("%d tools, %d rows, %d planted", #plantsOf(third), #profile.Held, #profile.Plants))
	end

	--==========================================================================
	-- 3. PICK UP: TWO AT ONCE, A DEATH IN THE MIDDLE, A WRITE THAT FAILS
	--==========================================================================
	say("\n-- pick up: the edges --")
	do
		local q, qPlot, qProfile = w.arrive("TwoPickups", -702, {
			{ id = "nubkin", tier = 2, grown = true },
			{ id = "petalpip", tier = 3, grown = true },
			{ id = "toadcap", tier = 2, grown = true },
		}, rowsOf(MAX - 1))
		-- One after the other with nothing in between: no frame, no yield.
		local first, firstWhy = w.PlantService.PickUpById(q, 1)
		local second, secondWhy = w.PlantService.PickUpById(q, 2)
		check(first == true and firstWhy == nil and second == false and secondWhy == "STORAGE_FULL",
			"two plants picked up in the same moment with room for one: the first is, the second is refused",
			string.format("%s/%s, %s/%s", tostring(first), tostring(firstWhy), tostring(second),
				tostring(secondWhy)))
		check(#plantsOf(q) == MAX and #qProfile.Held == MAX
				and census(qProfile.Held, rowKey) == census(plantsOf(q), toolKey)
				and modelFor(qPlot, 1) == nil and modelFor(qPlot, 2) ~= nil and #qProfile.Plants == 2,
			"24 Tools, the same 24 rows, and the second plant still planted",
			string.format("%d tools, %d rows", #plantsOf(q), #qProfile.Held))

		-- A body on its way out: no snapshot may be taken, and the record alone
		-- is counted.
		w.makeRoom(q, 1)
		local pack, bodyModel = q._backpack, q.Character
		q._fire.characterRemoving:Fire(bodyModel)
		task.wait(0.05)
		check(not w.CarryService.IsHeldRestored(q), "a body is on its way out: no snapshot may be taken")
		local mid, midWhy = w.PlantService.PickUpById(q, 2)
		check(mid == true and midWhy == nil and #qProfile.Held == MAX
				and countKey(qProfile.Held, rowKey, "petalpip:3:true") == 1,
			"with room for one, a pickup in the middle of a death is written straight on the record",
			string.format("%s/%s, %d rows", tostring(mid), tostring(midWhy), #qProfile.Held))
		local full, fullWhy = w.PlantService.PickUpById(q, 3)
		check(full == false and fullWhy == "STORAGE_FULL" and #qProfile.Held == MAX and modelFor(qPlot, 3) ~= nil,
			"and the next, with none, is refused in the middle of a death too",
			tostring(full) .. " / " .. tostring(fullWhy))
		step(w, q, function()
			q.Character = nil
			bodyModel:Destroy()
		end)
		step(w, q, function()
			pack:Destroy()
		end)
		local newPack = newBackpack(q, false)
		step(w, q, function()
			q._fire.childAdded:Fire(newPack)
		end)
		local newBodyModel = newBody(q, false)
		step(w, q, function()
			q._fire.characterAdded:Fire(newBodyModel)
		end)
		task.wait(0.8)
		check(#plantsOf(q) == MAX and #qProfile.Held == MAX
				and countKey(plantsOf(q), toolKey, "petalpip:3:true") == 1
				and census(qProfile.Held, rowKey) == census(plantsOf(q), toolKey) and #qProfile.Plants == 1,
			"the new body has all 24, the plant picked up mid-death among them, once",
			string.format("%d tools, %d rows", #plantsOf(q), #qProfile.Held))

		-- A record that refuses the write.
		local s, sPlot, sProfile = w.arrive("CannotWrite", -703, {
			{ id = "nubkin", tier = 4, grown = true },
		}, rowsOf(10))
		local gardenBefore = writesOf(s.Name, "Plants")
		heldFails[s] = true
		local answered, why = w.PlantService.PickUpById(s, 1)
		heldFails[s] = nil
		task.wait()
		check(answered == false and why == "NOT_RECORDED",
			"with room, but a record that refuses the write, the pickup is refused",
			tostring(answered) .. " / " .. tostring(why))
		check(#plantsOf(s) == 10 and countKey(plantsOf(s), toolKey, "nubkin:4:true") == 0
				and #sProfile.Held == 10 and modelFor(sPlot, 1) ~= nil and #sProfile.Plants == 1
				and writesOf(s.Name, "Plants") == gardenBefore and saidTo(s.Name) == 0,
			"the Tool made for it is taken back, the plant stays planted, and nothing is said",
			string.format("%d tools, %d rows", #plantsOf(s), #sProfile.Held))
		-- No record at all.
		ready[s] = false
		local none, noneWhy = w.PlantService.PickUpById(s, 1)
		ready[s] = true
		check(none == false and noneWhy == "NO_RECORD" and #plantsOf(s) == 10 and modelFor(sPlot, 1) ~= nil
				and saidTo(s.Name) == 0,
			"with no record at all the pickup is refused before anything is built",
			tostring(none) .. " / " .. tostring(noneWhy))
		local yes = w.PlantService.PickUpById(s, 1)
		check(yes == true and #plantsOf(s) == 11 and #sProfile.Held == 11
				and countKey(sProfile.Held, rowKey, "nubkin:4:true") == 1 and #sProfile.Plants == 0,
			"and it is picked up as soon as the record can be written")
	end

	--==========================================================================
	-- 4. A RECORD ALREADY PAST THE LIMIT IS LEFT AS IT IS
	--==========================================================================
	say("\n-- a record past the limit --")
	do
		local over = MAX + 3
		local o, oPlot, oProfile = w.arrive("PastTheLimit", -704, {
			{ id = "petalpip", tier = 2, grown = true },
		}, rowsOf(over), nil, true)
		local rowsBefore = census(oProfile.Held, rowKey)
		check(#oProfile.Held == over and #plantsOf(o) == over and census(plantsOf(o), toolKey) == rowsBefore,
			"a record of 27 rows is put back whole: 27 Tools, none dropped",
			string.format("%d tools, %d rows", #plantsOf(o), #oProfile.Held))
		local picked, why = w.PlantService.PickUpById(o, 1)
		-- A take is not this room's (2026-10-09): pods have their own, and 27
		-- plants leave it empty -- a pod past ITS limit is section 5's.
		local pod = w.pod("nubkin", 2)
		check(picked == false and why == "STORAGE_FULL" and modelFor(oPlot, 1) ~= nil
				and saidTo(o.Name, "STORAGE_FULL") == 1 and saidTo(o.Name) == 1,
			"a pickup is refused and the plant stays, and says why",
			saidTo(o.Name))
		w.CarryService.SyncHeldNow(o)
		task.wait()
		check(#oProfile.Held == over and census(oProfile.Held, rowKey) == rowsBefore and #plantsOf(o) == over,
			"and nothing cuts the record down to the limit: not the refusals, not a sync",
			string.format("%d rows", #oProfile.Held))
		die(w, o)
		check(#oProfile.Held == over and #plantsOf(o) == over and census(plantsOf(o), toolKey) == rowsBefore,
			"not a death either: all 27 are rebuilt",
			string.format("%d tools, %d rows", #plantsOf(o), #oProfile.Held))
		w.makeRoom(o, 3)
		local stillFull = w.PlantService.PickUpById(o, 1)
		check(stillFull == false and #oProfile.Held == MAX and #plantsOf(o) == MAX,
			"with three sold it holds 24, and is still full")
		w.makeRoom(o, 1)
		local yes = w.PlantService.PickUpById(o, 1)
		check(yes == true and #oProfile.Held == MAX and #plantsOf(o) == MAX
				and countKey(oProfile.Held, rowKey, "petalpip:2:true") == 1,
			"and at 23 the plant is picked up", string.format("%d tools, %d rows", #plantsOf(o), #oProfile.Held))
		pod:Destroy()
	end

	--==========================================================================
	-- 5. A POD AT A NEST, WITH THE POD ROOM FULL (pods' own room since 2026-10-09)
	--==========================================================================
	say("\n-- a pod at a nest: refused at 24 --")
	local r, _, rProfile = w.arrive("Raider", -705, {}, podRowsOf(MAX), nil, true)
	do
		local nestPod = w.pod("bellchime", 3, "spec-nest-1")
		local toolsBefore, rowsBefore = census(plantsOf(r), toolKey), census(rProfile.Held, rowKey)
		local heldBefore = writesOf(r.Name, "Held")
		local took = w.take(r, nestPod)
		check(took == false, "the take is refused", tostring(took))
		check(nestPod.Parent ~= nil and CollectionService:HasTag(nestPod, GameConfig.Tags.SeedPod)
				and nestPod:GetAttribute("NestId") == "spec-nest-1" and #w.nest == 0,
			"THE POD STAYS AT ITS NEST, untouched, and its parent is not woken", #w.nest)
		check(not w.CarryService.IsCarrying(r) and inArms(r) == nil and r:GetAttribute(ATTR.CarryingSpecies) == nil
				and stepsOf(r.Name, "steal") == 0 and w.metricsOf(r.Name, "raidStarted") == 0,
			"nothing is in the arms and no raid has begun")
		check(#plantsOf(r) == MAX and census(plantsOf(r), toolKey) == toolsBefore and #rProfile.Held == MAX
				and census(rProfile.Held, rowKey) == rowsBefore and writesOf(r.Name, "Held") == heldBefore,
			"the bag and the record are what they were")
		check(saidTo(r.Name, "POD_STORAGE_FULL") == 1 and saidTo(r.Name) == 1,
			"the player is told POD STORAGE FULL, once", saidTo(r.Name))
		for _ = 1, 6 do
			w.take(r, nestPod)
		end
		check(saidTo(r.Name) == 1 and nestPod.Parent ~= nil and #w.nest == 0 and not w.CarryService.IsCarrying(r),
			"holding the prompt six more times changes nothing and says nothing more", saidTo(r.Name))
		w.later(2.1)
		local loose = w.pod("nubkin", 2)
		local tookLoose = w.take(r, loose)
		check(tookLoose == false and loose.Parent ~= nil and saidTo(r.Name, "POD_STORAGE_FULL") == 2
				and #w.nest == 0,
			"a pod lying loose is refused the same way, a few seconds later, and the reason said again",
			saidTo(r.Name))
		loose:Destroy()

		-- A death and a rejoin do not make room.
		die(w, r)
		check(#plantsOf(r) == MAX and #rProfile.Held == MAX and census(plantsOf(r), toolKey) == toolsBefore,
			"after a death the 24 are rebuilt")
		w.later(2.1)
		check(w.take(r, nestPod) == false and nestPod.Parent ~= nil and #w.nest == 0
				and saidTo(r.Name, "POD_STORAGE_FULL") == 3,
			"and the new body is refused the same pod, for the same reason", saidTo(r.Name))
		leave(w, r)
		check(#rProfile.Held == MAX and census(rProfile.Held, rowKey) == rowsBefore,
			"the save they leave with is the 24 it was")
		r = w.arrive("Raider", -705, nil, nil, rProfile, true)
		check(#plantsOf(r) == MAX and w.take(r, nestPod) == false and nestPod.Parent ~= nil and #w.nest == 0
				and saidTo(r.Name, "POD_STORAGE_FULL") == 4,
			"they come back to the 24, and to the same refusal", saidTo(r.Name))

		-- Room is made: the pod is taken, carried home, and banked.
		w.makeRoom(r, 1)
		local yes = w.take(r, nestPod)
		check(yes == true and w.CarryService.IsCarrying(r) and inArms(r) ~= nil and nestPod.Parent == nil
				and #w.nest == 1 and w.nest[1].call == "TakePod" and stepsOf(r.Name, "steal") == 1,
			"with room for one the same pod is taken: in the arms, and its nest knows",
			tostring(yes))
		local banked = w.CarryService.Bank(r)
		check(banked == true and not w.CarryService.IsCarrying(r) and inArms(r) == nil,
			"at the red line it is banked", tostring(banked))
		-- Asked at once: the row is written in the call that made the Tool.
		check(#plantsOf(r) == MAX and #rProfile.Held == MAX
				and countKey(rProfile.Held, rowKey, "bellchime:3:false") == 1
				and countKey(plantsOf(r), toolKey, "bellchime:3:false") == 1
				and census(rProfile.Held, rowKey) == census(plantsOf(r), toolKey),
			"its Tool is in the bag and its row is on the record at once: 24 of each, the same 24",
			census(rProfile.Held, rowKey))
		check(r:GetAttribute(ATTR.BankedCount) == 1 and stepsOf(r.Name, "bank") == 1
				and w.metricsOf(r.Name, "raidEnded", "banked") == 1,
			"and the raid is counted as banked, once")
		-- THE WAIT STARTS AT THE BANK (2026-10-09, pods hatch in the Bag): the
		-- row and the Tool carry the same deadline, the ladder's own from now.
		local bankedRow, bankedTool = nil, nil
		for _, row in ipairs(rProfile.Held) do
			if row.Id == "bellchime" and row.Tier == 3 and row.Hatched == false then
				bankedRow = row
			end
		end
		for _, tool in ipairs(plantsOf(r)) do
			if toolKey(tool) == "bellchime:3:false" then
				bankedTool = tool
			end
		end
		local grow = SeedData.GrowSecondsFor(SeedData.Get("bellchime"), 3)
		check(bankedRow ~= nil and bankedTool ~= nil and type(bankedRow.HatchAt) == "number"
				and math.abs(bankedRow.HatchAt - (os.time() + grow)) <= 2
				and bankedTool:GetAttribute(GameConfig.HatchInBag.Attribute) == bankedRow.HatchAt,
			"its wait starts at the bank: the row and the Tool carry one deadline, the ladder's own from now",
			bankedRow and tostring(bankedRow.HatchAt))

		-- What was banked is still there after a death and a rejoin.
		die(w, r)
		check(#plantsOf(r) == MAX and #rProfile.Held == MAX
				and countKey(plantsOf(r), toolKey, "bellchime:3:false") == 1,
			"the banked pod is rebuilt after a death, once",
			string.format("%d tools, %d rows", #plantsOf(r), #rProfile.Held))
		leave(w, r)
		r = w.arrive("Raider", -705, nil, nil, rProfile, true)
		check(#plantsOf(r) == MAX and #rProfile.Held == MAX
				and countKey(plantsOf(r), toolKey, "bellchime:3:false") == 1,
			"and is in the bag after a rejoin",
			string.format("%d tools, %d rows", #plantsOf(r), #rProfile.Held))
	end

	--==========================================================================
	-- 6. A POD IN THE ARMS KEEPS ITS PLACE
	--==========================================================================
	say("\n-- a pod in the arms keeps its place --")
	-- In the POD room since 2026-10-09: a pickup, a hatch and an Instant Hatch
	-- take the plants' room, which a carried pod never touches.
	do
		local k, kPlot, kProfile = w.arrive("KeepsPlace", -706, {
			{ id = "nubkin", tier = 2, grown = true },
			{ id = "petalpip", tier = 2, ready = true },
			{ id = "spiretip", tier = 4, wait = 900 },
		}, podRowsOf(MAX - 1), nil, true)
		check(w.PlantService.OfferInstantHatch(k, kPlot, 3) == true and #w.prompts == 1,
			"a purchase dialog opens for a growing pod: the plants' room is empty")
		local took = w.take(k, w.pod("toadcap", 2))
		check(took == true and w.CarryService.IsCarrying(k), "with room for one more pod, a pod is taken")
		do
			local room, count, known = w.CarryService.PodRoom(k)
			local own, ownCount = w.CarryService.PodRoom(k, true)
			local plantRoom, plants = w.CarryService.HeldRoom(k)
			check(room == 0 and count == MAX and known == true and own == 1 and ownCount == MAX - 1
					and plantRoom == MAX and plants == 0,
				"the pod in the arms is counted in the pod room (no room for another pod, room for itself), "
					.. "and not in the plants'",
				string.format("%d and %d of %d; %d plants", count, ownCount, MAX, plants))
		end
		check(w.CarryService.GivePod(k, "spiretip", 1) == false and #kProfile.Held == MAX - 1,
			"a pod given on the run home is refused: the carried pod keeps its place")
		local picked, pickedWhy = w.PlantService.PickUpById(k, 1)
		local hatched, hatchedWhy = w.byHand(k, kPlot, 2)
		check(picked == true and pickedWhy == nil and hatched == true and hatchedWhy == nil
				and saidTo(k.Name, "STORAGE_FULL") == 0,
			"a pickup and a hatch go ahead on the run home: they take the plants' room, never the pod's place",
			string.format("%s / %s", tostring(pickedWhy), tostring(hatchedWhy)))
		-- The receipt for the dialog that was opened arrives on the run home.
		local decision, payload = w.deliver(k, "spec-arms-1")
		check(decision == GRANTED and payload ~= nil and #kProfile.Receipts == 1 and plantedIn(kPlot) == 0,
			"a purchase that arrives then hatches its pod: the plants' room has space",
			tostring(decision))
		local banked = w.CarryService.Bank(k)
		check(banked == true and countKey(kProfile.Held, rowKey, "toadcap:2:false") == 1
				and select(2, w.CarryService.PodRoom(k)) == MAX
				and census(kProfile.Held, rowKey) == census(plantsOf(k), toolKey),
			"and the pod is banked into the place that was kept for it: 24 of 24 pods",
			string.format("%d tools, %d rows", #plantsOf(k), #kProfile.Held))
	end

	--==========================================================================
	-- 7. THE RED LINE, WITH THE RECORD FILLED ON THE RUN HOME
	--==========================================================================
	say("\n-- the red line: refused at 24 --")
	do
		local b, _, bProfile = w.arrive("FillsOnTheWay", -707, {}, podRowsOf(MAX - 1), nil, true)
		check(w.take(b, w.pod("novaorb", 5)) == true and w.CarryService.IsCarrying(b),
			"a pod is taken with room for it")
		-- Every door a player uses keeps the carried pod's place (a pod given is
		-- refused, below), so this is the backstop: the record filled some other
		-- way on the run home -- here a plant handed back uncounted, as a rebuild
		-- hands one back, and written down by the bag's own snapshot.
		check(w.CarryService.GivePod(b, "spiretip", 1) == false and #bProfile.Held == MAX - 1,
			"a pod given on the run home is refused: the carried pod keeps its place")
		fillPodUncounted(b)
		check(#bProfile.Held == MAX and #plantsOf(b) == MAX, "the pod room is filled some other way: 24 of 24")
		local toolsBefore, rowsBefore = census(plantsOf(b), toolKey), census(bProfile.Held, rowKey)
		local heldBefore = writesOf(b.Name, "Held")
		local carriedBefore = inArms(b)
		local banked = w.CarryService.Bank(b)
		check(banked == false, "at the red line the bank is refused", tostring(banked))
		check(w.CarryService.IsCarrying(b) and inArms(b) ~= nil and inArms(b) == carriedBefore
				and b:GetAttribute(ATTR.CarryingSpecies) == "novaorb" and b:GetAttribute(ATTR.CarryingKg) == 5,
			"THE POD STAYS IN THE ARMS: the same pod, still carried")
		check(#plantsOf(b) == MAX and census(plantsOf(b), toolKey) == toolsBefore
				and countKey(plantsOf(b), toolKey, "novaorb:5:false") == 0,
			"no Tool is handed over: the bag is the bag it was", #plantsOf(b))
		check(#bProfile.Held == MAX and census(bProfile.Held, rowKey) == rowsBefore
				and writesOf(b.Name, "Held") == heldBefore,
			"the record is the record it was, and was not rewritten", #bProfile.Held)
		check(b:GetAttribute(ATTR.BankedCount) == nil and stepsOf(b.Name, "bank") == 0
				and w.metricsOf(b.Name, "raidEnded") == 0,
			"no success is reported: nothing banked, nothing counted, the raid not ended")
		check(saidTo(b.Name, "STORAGE_FULL_BANK") == 1 and saidTo(b.Name) == 1,
			"the carrier is told POD STORAGE FULL, once", saidTo(b.Name))

		-- The poll asks five times a second for as long as they stand there.
		for _ = 1, 25 do
			w.CarryService.Bank(b)
		end
		w.later(20)
		for _ = 1, 25 do
			w.CarryService.Bank(b)
		end
		check(saidTo(b.Name) == 1 and w.CarryService.IsCarrying(b) and #plantsOf(b) == MAX
				and #bProfile.Held == MAX and writesOf(b.Name, "Held") == heldBefore,
			"asked fifty more times over twenty seconds: nothing changes, nothing more is said, "
				.. "and the record is not written once", saidTo(b.Name))
		w.later(11)
		w.CarryService.Bank(b)
		w.CarryService.Bank(b)
		check(saidTo(b.Name, "STORAGE_FULL_BANK") == 2 and saidTo(b.Name) == 2,
			"half a minute on they are reminded, once", saidTo(b.Name))

		-- A death on the line: the pod is dropped where they stood, as any is.
		local lyingBefore = #looseOnMap()
		local dropped = die(w, b)
		check(dropped == true and not w.CarryService.IsCarrying(b) and #looseOnMap() == lyingBefore + 1,
			"a death drops the pod where they stood: it was never in the bag to lose")
		check(#plantsOf(b) == MAX and #bProfile.Held == MAX and census(plantsOf(b), toolKey) == toolsBefore
				and census(bProfile.Held, rowKey) == rowsBefore,
			"and the 24 are rebuilt: no plant lost, none made",
			string.format("%d tools, %d rows", #plantsOf(b), #bProfile.Held))
		local lying = nil
		for _, d in ipairs(looseOnMap()) do
			if d:GetAttribute("SpeciesId") == "novaorb" then
				lying = d
			end
		end
		w.later(2.1)
		local fullBefore = saidTo(b.Name, "POD_STORAGE_FULL")
		check(lying ~= nil and w.take(b, lying) == false and lying.Parent ~= nil
				and saidTo(b.Name, "POD_STORAGE_FULL") == fullBefore + 1,
			"the pod on the ground cannot be taken back while the record is full, and the reason is said")

		-- Room is made, and it is banked with nothing pressed.
		w.makeRoom(b, 1)
		check(lying ~= nil and w.take(b, lying) == true and w.CarryService.IsCarrying(b),
			"with room for one it is picked back up")
		local yes = w.CarryService.Bank(b)
		check(yes == true and not w.CarryService.IsCarrying(b) and #plantsOf(b) == MAX and #bProfile.Held == MAX
				and countKey(bProfile.Held, rowKey, "novaorb:5:false") == 1
				and countKey(plantsOf(b), toolKey, "novaorb:5:false") == 1
				and census(bProfile.Held, rowKey) == census(plantsOf(b), toolKey),
			"and the next time the line asks, it is banked: one Tool, one row",
			string.format("%d tools, %d rows", #plantsOf(b), #bProfile.Held))

		-- Room made while they stand on the line with the pod in their arms.
		local c, _, cProfile = w.arrive("WaitsOnTheLine", -708, {}, podRowsOf(MAX - 1), nil, true)
		w.take(c, w.pod("bellchime", 4))
		fillPodUncounted(c)
		task.wait()
		check(w.CarryService.Bank(c) == false and w.CarryService.IsCarrying(c) and #cProfile.Held == MAX,
			"another carrier is refused at the line, the pod in their arms")
		w.makeRoom(c, 1)
		check(w.CarryService.Bank(c) == true and not w.CarryService.IsCarrying(c) and #cProfile.Held == MAX
				and countKey(cProfile.Held, rowKey, "bellchime:4:false") == 1
				and census(cProfile.Held, rowKey) == census(plantsOf(c), toolKey),
			"one pod sold where they stand, and the pod is banked by itself",
			string.format("%d tools, %d rows", #plantsOf(c), #cProfile.Held))

		-- Leaving with the pod in the arms.
		local l, _, lProfile = w.arrive("LeavesCarrying", -709, {}, podRowsOf(MAX - 1), nil, true)
		w.take(l, w.pod("toadcap", 3))
		fillPodUncounted(l)
		task.wait()
		local leftRows = census(lProfile.Held, rowKey)
		check(w.CarryService.Bank(l) == false and #lProfile.Held == MAX, "a third is refused at the line")
		leave(w, l)
		check(#lProfile.Held == MAX and census(lProfile.Held, rowKey) == leftRows
				and countKey(lProfile.Held, rowKey, "toadcap:3:false") == 0,
			"the save they leave with is the 24 it was: nothing was cut to make room for the pod",
			string.format("%d rows", #lProfile.Held))
		local back = w.arrive("LeavesCarrying", -709, nil, nil, lProfile, true)
		check(#plantsOf(back) == MAX and #lProfile.Held == MAX and census(plantsOf(back), toolKey) == leftRows,
			"and they come back to the same 24")
	end

	--==========================================================================
	-- 8. THE RED LINE: A RECORD THAT CANNOT BE WRITTEN, AND NO RECORD YET
	--==========================================================================
	say("\n-- the red line: a record that cannot be written --")
	do
		local s, _, sProfile = w.arrive("BankCannotWrite", -710, {}, rowsOf(10), nil, true)
		check(w.take(s, w.pod("nubkin", 4)) == true, "a pod is taken")
		heldFails[s] = true
		local answered = w.CarryService.Bank(s)
		heldFails[s] = nil
		task.wait()
		check(answered == false and w.CarryService.IsCarrying(s) and inArms(s) ~= nil,
			"with room, but a record that refuses the write, the bank is refused and the pod stays in the arms",
			tostring(answered))
		check(#plantsOf(s) == 10 and countKey(plantsOf(s), toolKey, "nubkin:4:false") == 0
				and #sProfile.Held == 10 and saidTo(s.Name) == 0 and stepsOf(s.Name, "bank") == 0,
			"the Tool made for it is taken back, and nothing is said: it is not the player's to fix",
			string.format("%d tools, %d rows", #plantsOf(s), #sProfile.Held))
		-- The save has gone, or has not arrived.
		ready[s] = false
		local none = w.CarryService.Bank(s)
		ready[s] = true
		check(none == false and w.CarryService.IsCarrying(s) and #plantsOf(s) == 10 and saidTo(s.Name) == 0,
			"with no record at all the pod waits in the arms, and nothing is said", tostring(none))
		local yes = w.CarryService.Bank(s)
		check(yes == true and not w.CarryService.IsCarrying(s) and #plantsOf(s) == 11 and #sProfile.Held == 11
				and countKey(sProfile.Held, rowKey, "nubkin:4:false") == 1,
			"and is banked as soon as the record can be written")

		-- A TAKE BEFORE THE SAVE HAS ARRIVED (2026-09-30, found in review). It
		-- used to be allowed, the bank waiting for the record -- and a record
		-- that then arrived full left the pod in the arms for good: no bank, no
		-- planting, no single sale. Now the take waits for the record instead.
		local u, _, uProfile = w.arrive("SaveArriving", -711, {}, podRowsOf(MAX), nil, true)
		local early = w.pod("petalpip", 2)
		ready[u] = false
		local took = w.take(u, early)
		check(took == false and not w.CarryService.IsCarrying(u) and early.Parent ~= nil and saidTo(u.Name) == 0,
			"a player whose save has not arrived is refused at the nest, and told nothing: it is not full",
			tostring(took))
		ready[u] = true
		check(w.take(u, early) == false and not w.CarryService.IsCarrying(u) and early.Parent ~= nil
				and #uProfile.Held == MAX and saidTo(u.Name, "POD_STORAGE_FULL") == 1,
			"when the record arrives full, the take is refused for room and the reason is said: nothing is stuck "
				.. "in the arms")
		sellOnePod(u)
		check(w.take(u, early) == true and w.CarryService.IsCarrying(u) and w.CarryService.Bank(u) == true
				and #uProfile.Held == MAX and countKey(uProfile.Held, rowKey, "petalpip:2:false") == 1,
			"with room it is taken and banked into the record")
	end

	--==========================================================================
	-- 8b. A POD GIVEN: COUNTED AND WRITTEN DOWN, OR NOT GIVEN (2026-09-30)
	--
	-- GivePod is how the wheel pays a pod prize and how a paid pod product is
	-- granted. It used to hand a pod over past the limit without writing it
	-- down. The owner's rule: "Ordinary player actions must respect storage
	-- capacity without losing or duplicating a pod."
	--==========================================================================
	say("\n-- a pod given: counted --")
	do
		local gv, _, gvProfile = w.arrive("PodGiven", -712, {}, podRowsOf(MAX))
		local toolsBefore, rowsBefore = census(plantsOf(gv), toolKey), census(gvProfile.Held, rowKey)
		local refused = w.CarryService.GivePod(gv, "bellchime", 3)
		check(refused == false and census(plantsOf(gv), toolKey) == toolsBefore
				and census(gvProfile.Held, rowKey) == rowsBefore,
			"at 24 a pod given is refused: no Tool, no row", tostring(refused))
		sellOnePod(gv)
		local given = w.CarryService.GivePod(gv, "bellchime", 3)
		check(given == true and #plantsOf(gv) == MAX and #gvProfile.Held == MAX
				and countKey(gvProfile.Held, rowKey, "bellchime:3:false") == 1
				and countKey(plantsOf(gv), toolKey, "bellchime:3:false") == 1
				and census(gvProfile.Held, rowKey) == census(plantsOf(gv), toolKey),
			"with room it is handed over and written down in the same call: one Tool, one row",
			census(gvProfile.Held, rowKey))
		sellOnePod(gv)
		heldFails[gv] = true
		local unwritten = w.CarryService.GivePod(gv, "toadcap", 4)
		heldFails[gv] = nil
		task.wait()
		check(unwritten == false and countKey(plantsOf(gv), toolKey, "toadcap:4:false") == 0
				and #plantsOf(gv) == MAX - 1 and #gvProfile.Held == MAX - 1,
			"a row the record will not take: refused, and the Tool made for it taken back")
		ready[gv] = false
		local noRecord = w.CarryService.GivePod(gv, "toadcap", 4)
		ready[gv] = true
		check(noRecord == false and countKey(plantsOf(gv), toolKey, "toadcap:4:false") == 0,
			"no record at all: refused before anything is built")

		-- Between bodies: written straight on the record, and the new body gets it once.
		local pack, bodyModel = gv._backpack, gv.Character
		gv._fire.characterRemoving:Fire(bodyModel)
		task.wait(0.05)
		local midDeath = w.CarryService.GivePod(gv, "toadcap", 4)
		check(midDeath == true and countKey(gvProfile.Held, rowKey, "toadcap:4:false") == 1
				and #gvProfile.Held == MAX,
			"a pod given while a body is on its way out is written straight on the record")
		step(w, gv, function()
			gv.Character = nil
			bodyModel:Destroy()
		end)
		step(w, gv, function()
			pack:Destroy()
		end)
		local newPack = newBackpack(gv, false)
		step(w, gv, function()
			gv._fire.childAdded:Fire(newPack)
		end)
		local newBodyModel = newBody(gv, false)
		step(w, gv, function()
			gv._fire.characterAdded:Fire(newBodyModel)
		end)
		task.wait(0.8)
		check(#plantsOf(gv) == MAX and countKey(plantsOf(gv), toolKey, "toadcap:4:false") == 1
				and census(gvProfile.Held, rowKey) == census(plantsOf(gv), toolKey),
			"the new body has it, once", string.format("%d tools, %d rows", #plantsOf(gv), #gvProfile.Held))

		-- A record already past the limit is given nothing, and keeps every row.
		local o, _, oProfile = w.arrive("GivenPastTheLimit", -713, {}, podRowsOf(MAX + 2))
		local overRows = census(oProfile.Held, rowKey)
		check(w.CarryService.GivePod(o, "bellchime", 3) == false and #oProfile.Held == MAX + 2
				and census(oProfile.Held, rowKey) == overRows,
			"a record of 26 rows is given nothing, and keeps all 26")
	end

	--==========================================================================
	-- 8c. A PAID POD (the manifest's pod products are switched off; this spec
	-- sells one of its own)
	--
	-- The owner's rule: "Do not acknowledge any paid pod receipt without either
	-- a durable pod grant or a durable owed reward." The grant is GivePod,
	-- above, and StoreService acknowledges only once the save holding it has
	-- landed. A receipt the pod cannot be granted into is left open.
	--==========================================================================
	say("\n-- a paid pod --")
	do
		local b, _, bProfile = w.arrive("PodBuyer", -714, {}, podRowsOf(MAX), nil, true)
		local savesBefore = #saves
		local full = w.buyPod(b, "spec-pod-1")
		check(full == RETRY and #bProfile.Receipts == 0 and #plantsOf(b) == MAX and #bProfile.Held == MAX
				and countKey(plantsOf(b), toolKey, "bellchime:3:false") == 0 and #saves == savesBefore,
			"at 24 a paid pod is NOT acknowledged: no pod, no row, nothing in the ledger", tostring(full))

		-- A pod in the arms keeps its place against a paid pod too.
		sellOnePod(b)
		check(w.take(b, w.pod("toadcap", 2)) == true, "(a pod is taken with room for it)")
		local carrying = w.buyPod(b, "spec-pod-1")
		check(carrying == RETRY and #bProfile.Receipts == 0 and countKey(plantsOf(b), toolKey, "bellchime:3:false") == 0,
			"with 23 saved and a pod in the arms, the paid pod waits: the carried pod's place is kept",
			tostring(carrying))
		check(w.CarryService.Bank(b) == true and #bProfile.Held == MAX, "(the carried pod is banked into its place)")

		sellOnePod(b)
		local granted = w.buyPod(b, "spec-pod-1")
		local save = lastSave(b.Name)
		check(granted == GRANTED and countKey(bProfile.Held, rowKey, "bellchime:3:false") == 1
				and countKey(plantsOf(b), toolKey, "bellchime:3:false") == 1 and #bProfile.Held == MAX
				and save ~= nil and save.worked and save.held == MAX and save.receipts[1] == "spec-pod-1",
			"with room it is granted, written down, saved with the purchase, and only then acknowledged",
			tostring(granted))
		local again = w.buyPod(b, "spec-pod-1")
		check(again == GRANTED and countKey(plantsOf(b), toolKey, "bellchime:3:false") == 1 and #bProfile.Receipts == 1,
			"delivered again: acknowledged, and no second pod", tostring(again))

		-- A save that fails: open, and no second pod on the retry.
		sellOnePod(b)
		saveFails[b] = true
		local failing = w.buyPod(b, "spec-pod-2")
		local stillFailing = w.buyPod(b, "spec-pod-2")
		check(failing == RETRY and stillFailing == RETRY and countKey(plantsOf(b), toolKey, "bellchime:3:false") == 2,
			"the pod is given, the save fails: not acknowledged, and delivered again it gives no second pod")
		saveFails[b] = nil
		check(w.buyPod(b, "spec-pod-2") == GRANTED and countKey(plantsOf(b), toolKey, "bellchime:3:false") == 2
				and #bProfile.Receipts == 2,
			"acknowledged once the save has been written: two purchases, two pods")

		-- The record will not take the row: nothing given, not acknowledged.
		sellOnePod(b)
		heldFails[b] = true
		local unwritten = w.buyPod(b, "spec-pod-3")
		heldFails[b] = nil
		task.wait()
		check(unwritten == RETRY and countKey(plantsOf(b), toolKey, "bellchime:3:false") == 2
				and #bProfile.Receipts == 2,
			"a pod the record will not take is not handed over, and the receipt stays open")

		-- A death and a rejoin: the paid pods come back, once each.
		die(w, b)
		check(countKey(plantsOf(b), toolKey, "bellchime:3:false") == 2
				and census(bProfile.Held, rowKey) == census(plantsOf(b), toolKey),
			"after a death the two paid pods are rebuilt, once each")
		leave(w, b)
		local back = w.arrive("PodBuyer", -714, nil, nil, bProfile, true)
		check(countKey(plantsOf(back), toolKey, "bellchime:3:false") == 2 and #bProfile.Receipts == 2,
			"and they are in the bag after a rejoin")

		-- The manifest's own pod products stay off sale.
		local offSale = true
		for _, section in ipairs(GameConfig.Store.Sections) do
			for _, item in ipairs(GameConfig.Store.Items[section.id] or {}) do
				if item.kind == "pod" and (tonumber(item.product) or 0) > 0 then
					offSale = false
				end
			end
		end
		for _, item in ipairs(GameConfig.Store.InWorld or {}) do
			if item.kind == "pod" and (tonumber(item.product) or 0) > 0 then
				offSale = false
			end
		end
		check(offSale, "every pod product in the manifest still has an id of 0: none can be bought")
	end

	--==========================================================================
	-- 8d. THE BEGINNER'S RESERVED POD, WITH THE RECORD FULL
	--
	-- TutorialPodService lays one pod in the world with the beginner's name on
	-- it (CarryService.SpawnLoose, reserved) and lays another only when they
	-- hold none: TutorialData.HasOutstandingPod, over what they carry, what lies
	-- in the world reserved for them, and what their record and garden hold.
	-- The owner's rule: "Preserve the beginner tutorial's ability to recover" --
	-- so each storage refusal must leave the pod in one of those states: never
	-- lost (the tutorial could not recover it), never doubled (a second grant).
	--==========================================================================
	say("\n-- the beginner's reserved pod, with the record full --")
	do
		local nb, _, nbProfile = w.arrive("Beginner", -715, {}, plantRows(MAX), nil, true)
		local function reservedLying()
			for _, d in ipairs(map:GetChildren()) do
				if d:IsA("Model") and d.Parent and w.CarryService.ReservedFor(d) == nb.UserId then
					return d
				end
			end
			return nil
		end
		local function outstanding()
			return TutorialData.HasOutstandingPod({
				carrying = w.CarryService.IsCarrying(nb),
				inWorld = reservedLying() ~= nil,
				held = nbProfile.Held,
				plants = nbProfile.Plants,
			})
		end
		check(not outstanding(), "a beginner with a full record of plants holds no pod: the tutorial would lay one")
		local reserved = w.CarryService.SpawnLoose("nubkin", 1, CFrame.new(ORIGIN + Vector3.new(0, 0, -2)),
			"spec-nest", nb.UserId, true)
		check(reserved ~= nil and outstanding(), "it lays one, reserved for them, and now they hold one")
		w.later(2.1)
		-- Since 2026-10-09 pods have a room of their own: 24 plants never stop
		-- the take, and a beginner whose pods fill theirs holds pods and is laid
		-- no reserved one -- so the reserved pod is never refused for room.
		check(w.take(nb, reserved) == true and outstanding() and saidTo(nb.Name) == 0,
			"with the plants' room full the reserved pod is still taken -- pods have their own room -- and still "
				.. "counts as theirs")
		local dropped = die(w, nb)
		local lying = reservedLying()
		check(dropped == true and lying ~= nil and outstanding(),
			"a death on the way drops it where they stood, still reserved for them: nothing to grant again")
		check(lying ~= nil and w.take(nb, lying) == true and w.CarryService.Bank(nb) == true
				and countKey(nbProfile.Held, rowKey, "nubkin:1:false") == 1 and #nbProfile.Held == MAX + 1 and outstanding(),
			"picked back up and banked: one row for it beside the 24 plants, and the tutorial still sees it held")
	end

	--==========================================================================
	-- 9. WHAT THE SCRIPTS SAY
	--==========================================================================
	say("\n-- the source --")
	do
		local carry = sourceOf(Server:FindFirstChild("CarryService")) or ""
		local take = string.match(carry, "function CarryService%.TryTake(.-)\nend\n") or ""
		local roomAt = string.find(take, "CarryService.PodRoom(player)", 1, true)
		local lineAt = string.find(take, "EVERYTHING BELOW THIS LINE CHANGES THE WORLD", 1, true)
		check(roomAt ~= nil and lineAt ~= nil and roomAt < lineAt,
			"TryTake counts the room with its refusals, above the line where the world changes")
		local bankBody = string.match(carry, "local function bank(.-)\nend\n") or ""
		local askAt = string.find(bankBody, "CarryService.PodRoom(player, true)", 1, true)
		local buildAt = string.find(bankBody, "CreatureModel.BuildPod", 1, true)
		local recordAt = string.find(bankBody, "CarryService.RecordPod(player, species, tier, tool)", 1, true)
		local clearAt = string.find(bankBody, "carried[player] = nil", 1, true)
		check(askAt ~= nil and buildAt ~= nil and recordAt ~= nil and clearAt ~= nil
				and askAt < buildAt and buildAt < recordAt and recordAt < clearAt,
			"bank counts the room before it builds, and writes the row before the pod leaves the arms")
		local start = string.match(carry, "function CarryService%.Start(.-)\nend\n") or ""
		check(string.find(start, "MapService.IsInSafeZone(root.Position)", 1, true) ~= nil
				and string.find(start, "pcall(bank, player)", 1, true) ~= nil,
			"the red line's poll calls that same bank, and only inside the Safe Zone")

		local plant = sourceOf(Server:FindFirstChild("PlantService")) or ""
		local pick = string.match(plant, "\nfunction pickUp(.-)\nend\n") or ""
		-- 2026-10-04 (MY PLANTS): the same handover, now with the plant's own item
		-- id and the panel's Bag-only form; still on the record (`true`).
		local giveAt = string.find(pick,
			"CarryService.GiveHatched(player, entry.species, entry.tier,\n\t\tif bagOnly then -1 else nil, nil, true, entry.item)",
			1, true)
		local goneAt = string.find(pick, "byPlot[entry.id] = nil", 1, true)
		local savedAt = string.find(pick, "persist(entry.plot)", 1, true)
		check(giveAt ~= nil and goneAt ~= nil and savedAt ~= nil and giveAt < goneAt and goneAt < savedAt,
			"a pickup is handed over ON THE RECORD before the plant leaves the garden")

		local givePod = string.match(carry, "function CarryService%.GivePod(.-)\nend\n") or ""
		local podRoomAt = string.find(givePod, "CarryService.PodRoom(player)", 1, true)
		local podToolAt = string.find(givePod, "givePodTool(player, species, size,", 1, true)
		local podRecordAt = string.find(givePod, "CarryService.RecordPod(player, species, size, tool)", 1, true)
		local podBackAt = string.find(givePod, "tool:Destroy()", 1, true)
		check(podRoomAt ~= nil and podToolAt ~= nil and podRecordAt ~= nil and podBackAt ~= nil
				and podRoomAt < podToolAt and podToolAt < podRecordAt and podRecordAt < podBackAt,
			"GivePod counts the room before it builds, writes the row in the same call, and takes the Tool back if "
				.. "it cannot")
		-- Since ebc9db8 the console gives a Secret pod or plant -- through the
		-- counted givers only, so nothing there can go past the limit either.
		local admin = sourceOf(Server:FindFirstChild("AdminService")) or ""
		local adminHatched = 0
		for args in string.gmatch(admin, "CarryService%.GiveHatched%(([^\n]-)%)\n") do
			adminHatched += if string.find(args, ", true$") then 1 else 100
		end
		check(#admin > 0 and string.find(admin, "SpawnLoose", 1, true) == nil
				and string.find(admin, "CarryService.HeldRoom(target, nil, if form == \"pod\" then \"pod\" else nil)", 1, true) ~= nil
				and adminHatched == 1 and string.find(admin, "CarryService.GivePod(target,", 1, true) ~= nil,
			"the admin console gives only through GivePod and GiveHatched on the record, after HeldRoom",
			adminHatched)
	end

	--==========================================================================
	-- 10. THE WORDS
	--==========================================================================
	say("\n-- the words --")
	do
		local count = string.format("%d/%d", MAX, MAX)
		local full = ActionRefusal.notice("STORAGE_FULL")
		check(full ~= nil and full.kind == "blocked" and full.title == "PLANT STORAGE FULL"
				and string.find(full.detail, count, 1, true) ~= nil
				and string.find(string.lower(full.detail), "room", 1, true) ~= nil,
			"a refused pickup or hatch: PLANT STORAGE FULL, the limit's own number, and what makes room",
			full and (full.title .. " / " .. tostring(full.detail)))
		-- The pod room's own lines (2026-10-09), with ITS limit, Save.MaxPods.
		local pods = string.format("%d/%d", GameConfig.Save.MaxPods, GameConfig.Save.MaxPods)
		local line = ActionRefusal.notice("STORAGE_FULL_BANK")
		local words = string.lower(line and line.detail or "")
		check(line ~= nil and line.kind == "blocked" and line.title == "POD STORAGE FULL"
				and string.find(words, pods, 1, true) ~= nil and string.find(words, "free a slot", 1, true) ~= nil
				and string.find(words, "bank this pod", 1, true) ~= nil and full ~= nil and line.key ~= full.key,
			"at the red line: POD STORAGE FULL, the pods' own number, and that a free slot banks the pod",
			line and (line.title .. " / " .. tostring(line.detail)))
		local nest = ActionRefusal.notice("POD_STORAGE_FULL")
		check(nest ~= nil and nest.kind == "blocked" and nest.title == "POD STORAGE FULL"
				and string.find(nest.detail, pods, 1, true) ~= nil
				and string.find(string.lower(nest.detail), "room", 1, true) ~= nil,
			"at a nest: POD STORAGE FULL, the pods' own number, and what makes room",
			nest and (nest.title .. " / " .. tostring(nest.detail)))
	end
end

local bodyOk, bodyErr = pcall(body)
if not bodyOk then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(bodyErr))
end

ActionRefusal.capture(nil)
for _, w in ipairs(worlds) do
	if w.PlantService then
		pcall(w.PlantService.Init)
	end
	if w.CarryService then
		pcall(w.CarryService.Init)
	end
end
for _, plot in ipairs(plots) do
	plot:Destroy()
end
for _, pod in ipairs(looseOnMap()) do
	pod:Destroy()
end
fixture:Destroy()
for name, fn in pairs(real) do
	PlayerDataService[name] = fn
end

say(string.format("\nStorageDoorsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
