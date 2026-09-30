--!nocheck
--==============================================================================
-- Steal a Seed :: HatchStorageSpec
--
-- PLANT STORAGE FULL (2026-09-29). Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HatchStorageSpec"))
--
-- The defect: the saved record holds GameConfig.Save.MaxHeld plants and pods,
-- and a plant hatched past it was handed over and never saved -- gone at the
-- next death or rejoin, with its pod already out of the garden.
--
-- The owner's decision, and the rules that came with it:
--
--   "refuse the hatch and leave the pod planted and ready until the player
--    makes room. Show a clear, non-spamming 'plant storage full (24/24)'
--    message."
--   "ensure no pod is removed, plant granted, or success reported unless the
--    plant can be recorded safely."
--   "Do not silently delete or truncate an existing profile that already
--    exceeds the cap."
--   "prevent opening its purchase prompt when storage is full, but also handle
--    the race where storage fills after the prompt opens and before the paid
--    receipt arrives. Never acknowledge a receipt without delivering its
--    benefit".
--
-- And for that race, decided the same day:
--
--   "the purchase should make its intended pod ready immediately and persist
--    that state. Tell the player clearly that storage is full and they can
--    hatch the now-ready pod for free after making room. Acknowledge the paid
--    receipt only after that benefit is safely recorded."
--
-- And for the purchase that finds even that pod's wait already over, decided
-- 2026-09-30:
--
--   "save one credit for that purchase, acknowledge the receipt only after the
--    credit is safely saved, and make sure a duplicate receipt can't add a
--    second credit. The credit should only be used when an eligible hatch
--    actually succeeds."
--
-- And for a purchase that finds no pod at all, decided the same day: "if a
-- paid receipt arrives and the player has no unhatched pod, grant one saved
-- Instant Hatch credit ... Multiple separate purchases must remain separate
-- credits."
--
-- A pickup, a pod taken at a nest and a pod banked at the red line are refused
-- for room too: StorageDoorsSpec.
--
-- THE REAL PlantService, THE REAL CarryService AND THE REAL StoreService, each
-- loaded from its source. What stands in is what a spec cannot have:
-- PlotService (a plot with an owner), the profile store (replaced on the
-- PlayerDataService all three call, with a SetHeld and a Save that can be made
-- to fail), MarketplaceService (so the purchase dialog is a line in a list and
-- a receipt is a function call), the Players service, and the players --
-- tables whose signals are real and whose Backpack and body are real
-- instances, destroyed the way the engine destroys them (HeldRestoreSpec's).
--
-- NOTHING IS BOUGHT AND NO SAVE IS OPENED. A receipt here is a table handed to
-- the callback StoreService gave MarketplaceService.
--
-- Both doors are driven: the held prompt, by the name the prompt itself calls
-- (PlantService.HatchByHand -- the engine's Triggered cannot be fired from a
-- script), and the paid one, by a receipt through StoreService.
--
-- Not here: what the line looks like on a screen (HudLayoutSpec measures it,
-- NoticeSpec holds its words to the rules), a real purchase dialog, and what
-- Roblox does with a receipt it was told "not yet" -- which is Roblox's.
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

local HATCH = GameConfig.Plant.Hatch
local ROLL = HATCH.Roll
local KG = GameConfig.Attributes.CarryingKg
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

-- The manifest with a made-up Instant Hatch id, and the roll as asked for.
local SPEC_PRODUCT = 990077
local function configWith(rollOn)
	local rollConfig = setmetatable({ Enabled = rollOn, StudioPreview = false }, { __index = ROLL })
	local hatchConfig = setmetatable({ Roll = rollConfig }, { __index = HATCH })
	local plantConfig = setmetatable({ Hatch = hatchConfig }, { __index = GameConfig.Plant })
	local hatchItem = { key = "instanthatch", kind = "hatch", robux = 99, product = SPEC_PRODUCT }
	for _, item in ipairs(GameConfig.Store.InWorld or {}) do
		if item.kind == "hatch" then
			hatchItem = table.clone(item)
			hatchItem.product = SPEC_PRODUCT
		end
	end
	return setmetatable({
		Plant = plantConfig,
		Store = setmetatable({ InWorld = { hatchItem } }, { __index = GameConfig.Store }),
	}, { __index = GameConfig })
end

--==============================================================================
-- THE PLAYERS (HeldRestoreSpec's), AND THE SERVICE THEY ARE IN
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
fixture.Name = "HatchStorageSpecFixture"
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

local function newBody(p, announce)
	local body = Instance.new("Model")
	body.Name = p.Name .. "Body"
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

local function keyOf(id, tier, hatched)
	return string.format("%s:%d:%s", tostring(id), math.floor(tonumber(tier) or 0), tostring(hatched == true))
end

-- "nubkin:2:true x1, novaorb:4:true x2", in order, for a list of Tools or rows.
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

-- A record of `n` rows: plants and banked pods mixed, because the limit counts
-- both. Small ones, so that putting them back is quick.
local POOL = { "nubkin", "petalpip", "spiretip", "dunebud" }
local function rowsOf(n)
	local rows = {}
	for i = 1, n do
		table.insert(rows, { Id = POOL[(i % #POOL) + 1], Tier = 1, Hatched = i % 3 ~= 0 })
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
	IsPersistent = PlayerDataService.IsPersistent,
	AddInstantCredits = PlayerDataService.AddInstantCredits,
}
local ready = {}
local profiles = {}
-- A record that cannot be written, a garden that cannot be, and a save that
-- does not reach the disk.
local heldFails = {}
local plantsFail = {}
local saveFails = {}
-- A profile that can never be saved: the DataStores were out of reach when it
-- loaded (PlayerDataService.IsPersistent).
local temporary = {}
local writes = {}
local saves = {}
local tutorials = {}
-- One count for every write and every save, so that what came first can be
-- read off afterwards.
local stamp = 0
local function nextStamp()
	stamp += 1
	return stamp
end

-- A pod in a saved garden, by what it is: the rows carry no placement id.
local function podKey(row)
	return string.format("%s:%d", tostring(row.SpeciesId), math.floor(tonumber(row.Tier) or 0))
end

local function deadlinesOf(rows)
	local found = {}
	for _, row in ipairs(rows or {}) do
		found[podKey(row)] = row.HatchAt
	end
	return found
end

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
	if not profiles[p] or type(rows) ~= "table" or plantsFail[p] then
		return false
	end
	profiles[p].Plants = rows
	table.insert(writes, { who = p.Name, list = "Plants", rows = #rows,
		heldThen = #profiles[p].Held, toolsThen = #plantsOf(p), at = nextStamp() })
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
PlayerDataService.IsPersistent = function(p)
	return ready[p] == true and not temporary[p]
end
-- The saved Instant Hatches, kept the way the real writer keeps them (its own
-- checks are InstantCreditSpec's): whole numbers, never below zero, never past
-- the cap, and nil for a change that would break one of those.
PlayerDataService.AddInstantCredits = function(p, delta)
	local profile = if ready[p] then profiles[p] else nil
	if not profile or type(delta) ~= "number" or delta ~= delta or delta == 0
		or delta ~= math.floor(delta) then
		return nil
	end
	local balance = (profile.InstantCredits or 0) + delta
	if balance < 0 or balance > GameConfig.Save.MaxInstantCredits then
		return nil
	end
	profile.InstantCredits = balance
	table.insert(writes, { who = p.Name, list = "Credits", rows = balance, at = nextStamp() })
	return balance
end
-- What the profile held at the moment it was asked to be written: the ledger of
-- honoured purchases, every pod's deadline and the saved Instant Hatches,
-- copied, because all three go on changing afterwards.
PlayerDataService.Save = function(p)
	local profile = profiles[p]
	table.insert(saves, {
		who = p.Name,
		held = profile and #profile.Held or -1,
		worked = not saveFails[p],
		receipts = if profile then table.clone(profile.Receipts) else {},
		deadlines = deadlinesOf(profile and profile.Plants),
		credits = if profile then profile.InstantCredits or 0 else -1,
		at = nextStamp(),
	})
	return not saveFails[p]
end

local function gardenWrites(name)
	local n = 0
	for _, w in ipairs(writes) do
		if w.who == name and w.list == "Plants" then
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

local function savesOf(name)
	local n = 0
	for _, s in ipairs(saves) do
		if s.who == name then
			n += 1
		end
	end
	return n
end

local function lastSave(name)
	for i = #saves, 1, -1 do
		if saves[i].who == name then
			return saves[i]
		end
	end
	return nil
end

-- The row of one pod in a saved garden.
local function rowFor(profile, speciesId, tier)
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
	plot.Name = "HatchStorageSpecPlot" .. index
	plot.Archivable = false
	plot:SetAttribute("PreviewOnly", true)
	plot:SetAttribute(GameConfig.Attributes.PlotId, 300 + index)
	plot.Parent = Workspace
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	local y = 2400 + index * 60
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

local function podsIn(plot)
	local n = 0
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("PlacementId") ~= nil
			and CollectionService:HasTag(d, GameConfig.Tags.Planted) then
			n += 1
		end
	end
	return n
end

-- Pods in the order given, which is the order their placement ids are handed
-- out in. `ready` is a pod whose clock has run out; the others wait `wait`
-- seconds, or an hour and more.
local function gardenOf(pods)
	local rows = {}
	local stamp = os.time()
	for i, pod in ipairs(pods) do
		table.insert(rows, {
			SpeciesId = pod.id,
			Tier = pod.tier,
			PlantedAt = stamp - 5000,
			HatchAt = if pod.ready then stamp - 60 else stamp + (pod.wait or (9000 - i * 100)),
			X = -12 + i * 3,
			Z = -4,
			Stage = if pod.grown then 3 else 1,
			Facing = 0,
		})
	end
	return rows
end

local function makeWorld(rollOn)
	local w = { reveals = {}, prompts = {}, receipt = nil }
	local config = configWith(rollOn)
	-- The manifest's Instant Hatch entry, the same table PlantService reads its
	-- id off live, so a section can take the product off sale (10g).
	w.hatchItem = config.Store.InWorld[1]

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

	w.HatchRoll = loadWith(Shared.HatchRoll, { GameConfig = config, SeedData = SeedData })
	w.CarryService = loadWith(Server.CarryService, {
		NestService = require(Server:WaitForChild("NestService")),
		MapService = MapService,
		PlayerDataService = PlayerDataService,
		Metrics = require(Server:WaitForChild("Metrics")),
		GuardianCatch = require(Server:WaitForChild("GuardianCatch")),
		CarryGuard = require(Server:WaitForChild("CarryGuard")),
	}, nil, fakeGame)
	w.PlantService = loadWith(Server.PlantService, {
		PlotService = PlotService,
		PlayerDataService = PlayerDataService,
		CarryService = w.CarryService,
		PlantWander = PlantWander,
	}, { GameConfig = config, HatchRoll = w.HatchRoll }, fakeGame)
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
	function w.arrive(name, userId, pods, held, profile)
		local p = living(name, userId)
		profile = profile or { Plants = gardenOf(pods or {}), Held = held or {}, Almanac = {}, Receipts = {},
			InstantCredits = 0 }
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

	-- Here, armed, with a saved profile, and NO PLOT YET: the moment after a
	-- join when the profile has arrived and the garden is not in the world.
	-- `assign` puts them on a plot later, which is when their garden comes back.
	function w.arriveWithoutPlot(name, userId, profile)
		local p = living(name, userId)
		profiles[p] = profile
		ready[p] = true
		present[userId] = p
		newBackpack(p, false)
		newBody(p, false)
		w.CarryService.WatchHeld(p)
		w.CarryService.RestoreHeld(p)
		task.wait(0.4)
		local function assign()
			local plot = newPlot(plotOf, ownerOf)
			plotOf[p] = plot
			ownerOf[plot] = p
			assignedFn(p, plot)
			return plot
		end
		return p, assign
	end

	-- The held prompt. Answers what it said, why, the announcement it made (or
	-- nil), and whether it ran from start to finish without yielding.
	function w.byHand(p, plot, id)
		local before = #w.reveals
		local answered, why, done = nil, nil, false
		local thread = coroutine.create(function()
			answered, why = w.PlantService.HatchByHand(p, plot, id)
			done = true
		end)
		local resumed = coroutine.resume(thread)
		return answered, why, w.reveals[before + 1], resumed and done
	end

	-- The Instant Hatch key. Answers what it said, the announcement a hatch made
	-- (or nil), and how many purchase dialogs it opened.
	function w.offer(p, plot, id)
		local reveals, dialogs = #w.reveals, #w.prompts
		local answered = w.PlantService.OfferInstantHatch(p, plot, id)
		return answered, w.reveals[reveals + 1], #w.prompts - dialogs
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

-- A death, in the engine's order.
local function die(w, p)
	local pack, body = p._backpack, p.Character
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

-- Planted, ready, and with the free prompt on it.
local function stillReady(plot, id)
	local model = modelFor(plot, id)
	return model ~= nil and model:GetAttribute("Ready") == true and promptsOn(model, "HatchPrompt") == 1
end

-- The Instant Hatch prompt on a planted pod, or nil.
local function instantPromptOn(model)
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.Name == "InstantHatchPrompt" then
				return d
			end
		end
	end
	return nil
end

-- What a player with a saved Instant Hatch is shown instead of a price.
local SAVED_TEXT = GameConfig.Plant.InstantHatch.SavedActionText

-- The prompt shows a price (no credit held), or shows it is free (one held).
local function pricedPrompt(model)
	local prompt = instantPromptOn(model)
	return prompt ~= nil and prompt:GetAttribute("Robux") ~= nil and prompt:GetAttribute("RobuxProduct") ~= nil
		and prompt:GetAttribute("SavedHatch") == nil and prompt.ActionText == GameConfig.Plant.InstantHatch.ActionText
end
local function freePrompt(model)
	local prompt = instantPromptOn(model)
	return prompt ~= nil and prompt:GetAttribute("Robux") == nil and prompt:GetAttribute("RobuxProduct") == nil
		and prompt:GetAttribute("SavedHatch") == true and SAVED_TEXT ~= nil and prompt.ActionText == SAVED_TEXT
end

-- Planted and still counting down, with the paid prompt on it and not the free.
local function stillGrowing(plot, id)
	local model = modelFor(plot, id)
	return model ~= nil and model:GetAttribute("Ready") ~= true and promptsOn(model, "HatchPrompt") == 0
		and promptsOn(model, "InstantHatchPrompt") == 1
end

-- A garden is put back in the order its rows were saved in, so a pod may come
-- back under another placement id. Its deadline is its own.
local function idWithDeadline(plot, deadline)
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("PlacementId") ~= nil
			and CollectionService:HasTag(d, GameConfig.Tags.Planted)
			and d:GetAttribute("HatchAt") == deadline then
			return d:GetAttribute("PlacementId")
		end
	end
	return nil
end

local function body()
	local loadOk, loadErr = pcall(function()
		makeWorld(true)
	end)
	local w = worlds[1]
	check(loadOk and w ~= nil and type(w.receipt) == "function" and w.HatchRoll.live() == true,
		"the real PlantService, CarryService and StoreService load, with the roll switched on", loadErr)
	if not (loadOk and w and w.receipt) then
		return
	end
	check(MAX == 24, "the saved record holds 24 plants and pods", MAX)

	--==========================================================================
	-- 1. TWENTY-THREE, AND THE ONE THAT MAKES TWENTY-FOUR
	--==========================================================================
	say("\n-- 23 to 24 --")
	local p, plot, profile = w.arrive("Boundary", -601, {
		{ id = "nubkin", tier = 1, ready = true },
		{ id = "novaorb", tier = 2, ready = true },
		{ id = "bellchime", tier = 1, ready = true },
	}, rowsOf(MAX - 1))
	check(w.CarryService.IsHeldRestored(p) and #plantsOf(p) == MAX - 1 and #profile.Held == MAX - 1,
		"a player with 23 plants and pods saved has all 23 in the bag",
		string.format("%d tools, %d rows", #plantsOf(p), #profile.Held))
	do
		local room, count, known = w.CarryService.HeldRoom(p)
		check(room == 1 and count == MAX - 1 and known == true, "and room for one more",
			string.format("%s/%s/%s", tostring(room), tostring(count), tostring(known)))
	end
	check(stillReady(plot, 1) and stillReady(plot, 2) and stillReady(plot, 3) and podsIn(plot) == 3,
		"three pods stand ready in the garden")
	do
		-- The held prompt has a name now, and the name is no way round the owner
		-- check: somebody else, with room of their own, opens nothing here.
		local stranger = w.arrive("Stranger", -600, {}, rowsOf(2))
		local answered, why, payload = w.byHand(stranger, plot, 1)
		check(answered == false and why == nil and payload == nil and stillReady(plot, 1)
				and #plantsOf(stranger) == 2 and #plantsOf(p) == MAX - 1 and #profile.Held == MAX - 1
				and saidTo(stranger.Name) == 0,
			"a stranger holding the owner's pod hatches nothing, for anybody, and is told nothing",
			tostring(answered) .. " / " .. tostring(why))
		check(w.PlantService.HatchByHand(p, plot, 99) == false
				and w.PlantService.HatchByHand(p, fixture, 1) == false,
			"and a pod that is not there, or a plot that is not one, is nothing")
	end
	do
		local gardenBefore = gardenWrites(p.Name)
		local answered, why, payload, ranThrough = w.byHand(p, plot, 1)
		check(answered == true and why == nil and ranThrough,
			"the 24th is hatched, in one step", tostring(answered) .. " / " .. tostring(why))
		check(#plantsOf(p) == MAX and #profile.Held == MAX
				and countKey(profile.Held, rowKey, "nubkin:1:true") == countKey(plantsOf(p), toolKey, "nubkin:1:true")
				and census(profile.Held, rowKey) == census(plantsOf(p), toolKey),
			"its Tool is in the bag and its row is on the record: 24 of each, the same 24",
			census(profile.Held, rowKey))
		local garden = lastGardenWrite(p.Name)
		check(gardenWrites(p.Name) == gardenBefore + 1 and garden ~= nil and garden.rows == 2
				and garden.heldThen == MAX and modelFor(plot, 1) == nil and podsIn(plot) == 2,
			"the garden is saved without the pod, and only after the plant was on the record",
			garden and string.format("%d pods, %d rows then", garden.rows, garden.heldThen))
		check(payload ~= nil and payload.species == "nubkin" and payload.tier == 1
				and saidTo(p.Name) == 0,
			"the hatch is announced, and nothing is refused")
	end

	--==========================================================================
	-- 2. FULL: THE HATCH IS REFUSED, AND THE POD STAYS PLANTED AND READY
	--==========================================================================
	say("\n-- refused at 24 --")
	do
		local room, count = w.CarryService.HeldRoom(p)
		check(room == 0 and count == MAX, "the record is full: 24 of 24", string.format("%d/%d", count, MAX))
		local toolsBefore, rowsBefore = census(plantsOf(p), toolKey), census(profile.Held, rowKey)
		local gardenBefore, tutorialsBefore = gardenWrites(p.Name), #tutorials
		local answered, why, payload, ranThrough = w.byHand(p, plot, 2)
		check(answered == false and why == "STORAGE_FULL" and ranThrough,
			"the next hatch is refused, for room", tostring(answered) .. " / " .. tostring(why))
		check(#plantsOf(p) == MAX and census(plantsOf(p), toolKey) == toolsBefore,
			"no plant is handed over: the bag is the bag it was", #plantsOf(p))
		check(#profile.Held == MAX and census(profile.Held, rowKey) == rowsBefore,
			"the record is the record it was", #profile.Held)
		check(stillReady(plot, 2) and podsIn(plot) == 2 and w.PlantService.CountIn(plot) == 2
				and gardenWrites(p.Name) == gardenBefore and #profile.Plants == 2,
			"the pod is still planted and still ready, and the garden was not rewritten")
		check(payload == nil and profile.Almanac.novaorb == nil and #tutorials == tutorialsBefore,
			"no success is reported: no announcement, nothing learned, nothing counted")
		check(saidTo(p.Name, "STORAGE_FULL") == 1 and saidTo(p.Name) == 1,
			"the player is told PLANT STORAGE FULL, once", saidTo(p.Name))

		-- Held again and again.
		for _ = 1, 4 do
			w.byHand(p, plot, 2)
			w.byHand(p, plot, 3)
		end
		check(saidTo(p.Name) == 1 and #plantsOf(p) == MAX and #profile.Held == MAX and podsIn(plot) == 2,
			"holding the prompt eight more times changes nothing and says nothing more", saidTo(p.Name))
		task.wait(2.1)
		w.byHand(p, plot, 3)
		check(saidTo(p.Name, "STORAGE_FULL") == 2 and saidTo(p.Name) == 2,
			"a try a few seconds later is answered again: the line is not said once and never after",
			saidTo(p.Name))
	end

	--==========================================================================
	-- 3. MAKING ROOM, AND TRYING AGAIN
	--==========================================================================
	say("\n-- making room --")
	do
		check(w.makeRoom(p, 1) == 1 and #plantsOf(p) == MAX - 1 and #profile.Held == MAX - 1,
			"one plant sold or planted: 23 in the bag, 23 on the record",
			string.format("%d tools, %d rows", #plantsOf(p), #profile.Held))
		local answered, why, payload = w.byHand(p, plot, 2)
		check(answered == true and why == nil and payload ~= nil and payload.species == "novaorb"
				and payload.tier == 2,
			"the pod that was refused now hatches: the same pod, the same plant",
			tostring(answered) .. " / " .. tostring(why))
		check(#plantsOf(p) == MAX and #profile.Held == MAX
				and countKey(profile.Held, rowKey, "novaorb:2:true") == 1
				and countKey(plantsOf(p), toolKey, "novaorb:2:true") == 1
				and modelFor(plot, 2) == nil and podsIn(plot) == 1 and #profile.Plants == 1,
			"one Tool, one row, and the pod out of the garden",
			census(profile.Held, rowKey))
		local again = w.byHand(p, plot, 3)
		check(again == false and stillReady(plot, 3) and #plantsOf(p) == MAX and #profile.Held == MAX,
			"and the record is full again: the last pod waits its turn")
	end

	--==========================================================================
	-- 4. TWO AT NEARLY THE SAME TIME
	--==========================================================================
	say("\n-- two at once --")
	do
		local q, qPlot, qProfile = w.arrive("TwoAtOnce", -602, {
			{ id = "nubkin", tier = 2, ready = true },
			{ id = "petalpip", tier = 3, ready = true },
		}, rowsOf(MAX - 1))
		-- One after the other with nothing in between: no frame, no yield.
		local first, firstWhy = w.PlantService.HatchByHand(q, qPlot, 1)
		local second, secondWhy = w.PlantService.HatchByHand(q, qPlot, 2)
		check(first == true and second == false and secondWhy == "STORAGE_FULL" and firstWhy == nil,
			"two pods held in the same moment with room for one: the first hatches, the second is refused",
			string.format("%s/%s, %s/%s", tostring(first), tostring(firstWhy), tostring(second),
				tostring(secondWhy)))
		check(#plantsOf(q) == MAX and #qProfile.Held == MAX
				and census(qProfile.Held, rowKey) == census(plantsOf(q), toolKey)
				and stillReady(qPlot, 2) and modelFor(qPlot, 1) == nil and #qProfile.Plants == 1,
			"24 Tools, the same 24 rows, and the second pod still planted and ready",
			string.format("%d tools, %d rows", #plantsOf(q), #qProfile.Held))

		-- A pod given and a hatch in the same moment: the pod's Tool is in the
		-- bag and its row is not written yet when the hatch is asked for.
		local r, rPlot, rProfile = w.arrive("GivenThenHatch", -603, {
			{ id = "nubkin", tier = 1, ready = true },
		}, rowsOf(MAX - 1))
		local handed = w.CarryService.GivePod(r, "dunebud", 1)
		local answered, why = w.PlantService.HatchByHand(r, rPlot, 1)
		task.wait()
		check(handed == true and answered == false and why == "STORAGE_FULL",
			"a pod given in the same moment takes the last place: the hatch counts it, and is refused",
			tostring(answered) .. " / " .. tostring(why))
		check(#plantsOf(r) == MAX and #rProfile.Held == MAX
				and census(rProfile.Held, rowKey) == census(plantsOf(r), toolKey) and stillReady(rPlot, 1),
			"24 Tools and the same 24 rows: nothing in the bag is off the record",
			string.format("%d tools, %d rows", #plantsOf(r), #rProfile.Held))

		-- A plant handed over by a door that does not write its row at once (a
		-- rebuild's, an admin's): its Tool is in the bag and its row is not on
		-- the record when the hatch is asked for. The count catches the record
		-- up with the bag first.
		local u, uPlot, uProfile = w.arrive("UnwrittenThenHatch", -618, {
			{ id = "nubkin", tier = 1, ready = true },
		}, rowsOf(MAX - 1))
		local unwritten = w.CarryService.GiveHatched(u, SeedData.Get("dunebud"), 2)
		local rowsThen = #uProfile.Held
		local refused, refusedWhy = w.PlantService.HatchByHand(u, uPlot, 1)
		task.wait()
		check(unwritten == true and rowsThen == MAX - 1 and #plantsOf(u) == MAX and refused == false
				and refusedWhy == "STORAGE_FULL",
			"a plant in the bag whose row is not written yet takes the last place: the hatch counts it first",
			string.format("%s / %s, %d rows then", tostring(refused), tostring(refusedWhy), rowsThen))
		check(#plantsOf(u) == MAX and #uProfile.Held == MAX
				and census(uProfile.Held, rowKey) == census(plantsOf(u), toolKey)
				and countKey(uProfile.Held, rowKey, "dunebud:2:true") == 1 and stillReady(uPlot, 1),
			"24 Tools and the same 24 rows, that plant's among them, and the pod still planted and ready",
			string.format("%d tools, %d rows", #plantsOf(u), #uProfile.Held))
	end

	--==========================================================================
	-- 5. A DEATH
	--==========================================================================
	say("\n-- a death --")
	do
		-- Refused, then dies.
		die(w, p)
		check(#plantsOf(p) == MAX and #profile.Held == MAX
				and census(profile.Held, rowKey) == census(plantsOf(p), toolKey),
			"after a refusal and a death the 24 are rebuilt: no plant lost, none made",
			string.format("%d tools, %d rows", #plantsOf(p), #profile.Held))
		check(stillReady(plot, 3) and podsIn(plot) == 1 and #profile.Plants == 1,
			"and the refused pod is still planted and ready")
		task.wait(1.4)
		local answered, why = w.byHand(p, plot, 3)
		check(answered == false and why == "STORAGE_FULL" and #plantsOf(p) == MAX,
			"the new body is refused the same way: the record decides, not the body")

		-- A hatch that lands while the body is being replaced, with room for it.
		local d, dPlot, dProfile = w.arrive("DiesWithRoom", -604, {
			{ id = "nubkin", tier = 3, ready = true },
			{ id = "petalpip", tier = 1, ready = true },
		}, rowsOf(MAX - 1))
		local pack, bodyModel = d._backpack, d.Character
		d._fire.characterRemoving:Fire(bodyModel)
		task.wait(0.05)
		check(not w.CarryService.IsHeldRestored(d), "a body is on its way out: no snapshot may be taken")
		local midAnswered, midWhy = w.byHand(d, dPlot, 1)
		check(midAnswered == true and midWhy == nil and #dProfile.Held == MAX
				and countKey(dProfile.Held, rowKey, "nubkin:3:true") == 1,
			"with room for one, a hatch in the middle of a death is written straight on the record",
			string.format("%s/%s, %d rows", tostring(midAnswered), tostring(midWhy), #dProfile.Held))
		local fullAnswered, fullWhy = w.byHand(d, dPlot, 2)
		check(fullAnswered == false and fullWhy == "STORAGE_FULL" and #dProfile.Held == MAX
				and modelFor(dPlot, 2) ~= nil,
			"and the next, with none, is refused in the middle of a death too",
			tostring(fullAnswered) .. " / " .. tostring(fullWhy))
		step(w, d, function()
			d.Character = nil
			bodyModel:Destroy()
		end)
		step(w, d, function()
			pack:Destroy()
		end)
		local newPack = newBackpack(d, false)
		step(w, d, function()
			d._fire.childAdded:Fire(newPack)
		end)
		local newBodyModel = newBody(d, false)
		step(w, d, function()
			d._fire.characterAdded:Fire(newBodyModel)
		end)
		task.wait(0.8)
		check(#plantsOf(d) == MAX and #dProfile.Held == MAX
				and countKey(plantsOf(d), toolKey, "nubkin:3:true") == 1
				and census(dProfile.Held, rowKey) == census(plantsOf(d), toolKey),
			"the new body has all 24, the plant that hatched mid-death among them, once",
			string.format("%d tools, %d rows", #plantsOf(d), #dProfile.Held))
		check(podsIn(dPlot) == 1 and #dProfile.Plants == 1 and dProfile.Plants[1].SpeciesId == "petalpip",
			"and the garden has the refused pod and no other")
	end

	--==========================================================================
	-- 6. LEAVING, AND COMING BACK
	--==========================================================================
	say("\n-- leaving and rejoining --")
	do
		local l, lPlot, lProfile = w.arrive("LeavesFull", -605, {
			{ id = "spiretip", tier = 2, ready = true },
		}, rowsOf(MAX))
		local answered, why = w.byHand(l, lPlot, 1)
		check(answered == false and why == "STORAGE_FULL" and #lProfile.Held == MAX,
			"a player with 24 saved is refused")
		local rowsBefore = census(lProfile.Held, rowKey)
		local pack, bodyModel = l._backpack, l.Character
		for _, fn in ipairs(leaving) do
			fn(l)
		end
		l.Parent = nil
		step(w, l, function()
			l._fire.characterRemoving:Fire(bodyModel)
		end)
		step(w, l, function()
			l.Character = nil
			bodyModel:Destroy()
		end)
		step(w, l, function()
			pack:Destroy()
		end)
		task.wait(0.3)
		check(#lProfile.Held == MAX and census(lProfile.Held, rowKey) == rowsBefore
				and #lProfile.Plants == 1 and lProfile.Plants[1].SpeciesId == "spiretip"
				and lProfile.Plants[1].Stage == 1,
			"the save they leave with has the 24 and the pod: the refusal cost nothing",
			string.format("%d rows, %d pods", #lProfile.Held, #lProfile.Plants))

		ready[l] = nil
		local back, backPlot = w.arrive("LeavesFull", -605, nil, nil, lProfile)
		check(#plantsOf(back) == MAX and #lProfile.Held == MAX
				and census(lProfile.Held, rowKey) == rowsBefore and stillReady(backPlot, 1),
			"they come back to the 24, and to the pod, planted and ready",
			string.format("%d tools, %d rows", #plantsOf(back), #lProfile.Held))
		local stillNo, stillWhy = w.byHand(back, backPlot, 1)
		check(stillNo == false and stillWhy == "STORAGE_FULL", "which is still refused")
		w.makeRoom(back, 2)
		local yes = w.byHand(back, backPlot, 1)
		check(yes == true and #plantsOf(back) == MAX - 1 and #lProfile.Held == MAX - 1
				and countKey(lProfile.Held, rowKey, "spiretip:2:true") >= 1 and #lProfile.Plants == 0,
			"and hatches once there is room: 22 and the new plant",
			string.format("%d tools, %d rows", #plantsOf(back), #lProfile.Held))
	end

	--==========================================================================
	-- 7. A RECORD THAT CANNOT BE WRITTEN
	--==========================================================================
	say("\n-- a record that cannot be written --")
	do
		local s, sPlot, sProfile = w.arrive("CannotWrite", -606, {
			{ id = "nubkin", tier = 4, ready = true },
			-- A plant of a kind they already hold two of.
			{ id = "nubkin", tier = 1, ready = true },
		}, rowsOf(10))
		heldFails[s] = true
		local answered, why, payload = w.byHand(s, sPlot, 1)
		heldFails[s] = nil
		task.wait()
		check(answered == false and why == "NOT_RECORDED" and payload == nil,
			"with room, but a record that refuses the write, the hatch is refused",
			tostring(answered) .. " / " .. tostring(why))
		check(#plantsOf(s) == 10 and countKey(plantsOf(s), toolKey, "nubkin:4:true") == 0
				and #sProfile.Held == 10,
			"and the Tool that was made for it is taken back: nothing is held that is not recorded",
			string.format("%d tools, %d rows", #plantsOf(s), #sProfile.Held))
		check(stillReady(sPlot, 1) and #sProfile.Plants == 2 and sProfile.Almanac.nubkin == nil
				and saidTo(s.Name) == 0,
			"the pod stays, nothing is learned, and nothing is said: it is not the player's to fix")

		-- The same, for a plant of a kind already held: a row of that kind on the
		-- record is some other plant's, and does not answer for this one.
		local kindBefore = countKey(sProfile.Held, rowKey, "nubkin:1:true")
		heldFails[s] = true
		local same, sameWhy = w.byHand(s, sPlot, 2)
		heldFails[s] = nil
		task.wait()
		check(kindBefore >= 1 and same == false and sameWhy == "NOT_RECORDED" and #plantsOf(s) == 10
				and #sProfile.Held == 10 and countKey(plantsOf(s), toolKey, "nubkin:1:true") == kindBefore
				and stillReady(sPlot, 2),
			"a plant of a kind already held is refused the same way: another plant's row is not its own",
			string.format("%s/%s, %d tools, %d rows", tostring(same), tostring(sameWhy), #plantsOf(s),
				#sProfile.Held))

		-- No record at all: the profile has gone.
		ready[s] = false
		local none, noneWhy = w.byHand(s, sPlot, 1)
		ready[s] = true
		check(none == false and noneWhy == "NO_RECORD" and #plantsOf(s) == 10 and stillReady(sPlot, 1)
				and saidTo(s.Name) == 0,
			"with no record at all the hatch is refused before anything is built",
			tostring(none) .. " / " .. tostring(noneWhy))

		local yes = w.byHand(s, sPlot, 1)
		check(yes == true and #plantsOf(s) == 11 and #sProfile.Held == 11
				and countKey(sProfile.Held, rowKey, "nubkin:4:true") == 1,
			"and hatches as soon as the record can be written")
		local other = w.byHand(s, sPlot, 2)
		check(other == true and #plantsOf(s) == 12 and #sProfile.Held == 12
				and countKey(sProfile.Held, rowKey, "nubkin:1:true") == kindBefore + 1
				and census(sProfile.Held, rowKey) == census(plantsOf(s), toolKey),
			"and so does the other, with a row of its own beside the ones that were there")
	end

	--==========================================================================
	-- 8. A RECORD ALREADY PAST THE LIMIT IS LEFT AS IT IS
	--==========================================================================
	say("\n-- a record past the limit --")
	do
		local over = MAX + 3
		local o, oPlot, oProfile = w.arrive("PastTheLimit", -607, {
			{ id = "petalpip", tier = 2, ready = true },
		}, rowsOf(over))
		local rowsBefore = census(oProfile.Held, rowKey)
		check(#oProfile.Held == over and #plantsOf(o) == over and census(plantsOf(o), toolKey) == rowsBefore,
			"a record of 27 rows is put back whole: 27 Tools, none dropped",
			string.format("%d tools, %d rows", #plantsOf(o), #oProfile.Held))
		local room, count = w.CarryService.HeldRoom(o)
		check(room == 0 and count == over, "it has no room, and says how many it holds",
			string.format("%d/%d", count, MAX))
		local answered, why = w.byHand(o, oPlot, 1)
		check(answered == false and why == "STORAGE_FULL" and stillReady(oPlot, 1),
			"a hatch is refused and the pod stays")
		w.CarryService.SyncHeldNow(o)
		task.wait()
		check(#oProfile.Held == over and census(oProfile.Held, rowKey) == rowsBefore and #plantsOf(o) == over,
			"and nothing cuts the record down to the limit: not the refusal, not a sync",
			string.format("%d rows", #oProfile.Held))
		die(w, o)
		check(#oProfile.Held == over and #plantsOf(o) == over
				and census(plantsOf(o), toolKey) == rowsBefore,
			"not a death either: all 27 are rebuilt",
			string.format("%d tools, %d rows", #plantsOf(o), #oProfile.Held))
		w.makeRoom(o, 1)
		check(#oProfile.Held == over - 1 and #plantsOf(o) == over - 1,
			"a sale takes off the one plant sold, and only that one", #oProfile.Held)
		w.makeRoom(o, 2)
		local stillFull = w.byHand(o, oPlot, 1)
		check(stillFull == false and #oProfile.Held == MAX and #plantsOf(o) == MAX,
			"at 24 it is still full")
		w.makeRoom(o, 1)
		local yes = w.byHand(o, oPlot, 1)
		check(yes == true and #oProfile.Held == MAX and #plantsOf(o) == MAX
				and countKey(oProfile.Held, rowKey, "petalpip:2:true") >= 1,
			"and at 23 the pod hatches", string.format("%d tools, %d rows", #plantsOf(o), #oProfile.Held))

		-- The door such a record comes in by: the loader, as it is handed a save.
		-- It used to stop reading at 24 rows and say nothing about the rest.
		local schemaOk, schema = pcall(loadWith, Server.ProfileSchema, {})
		check(schemaOk and type(schema) == "table" and type(schema.Sanitise) == "function",
			"the real ProfileSchema loads", schema)
		if schemaOk and type(schema) == "table" then
			local saved = rowsOf(over)
			local loaded = schema.Sanitise({ Held = saved })
			local inOrder = #loaded.Held == #saved
			for i, row in ipairs(saved) do
				local got = loaded.Held[i]
				if not (got and got.Id == row.Id and got.Tier == row.Tier and got.Hatched == row.Hatched) then
					inOrder = false
				end
			end
			check(#loaded.Held == over and inOrder,
				"a save of 27 rows is loaded with all 27, in the order they were saved: nothing is cut off",
				#loaded.Held)
			local mixed = schema.Sanitise({ Held = {
				{ Id = "nubkin", Tier = 1, Hatched = true },
				{ Id = "not-a-plant", Tier = 1, Hatched = true },
				{ Id = "petalpip", Tier = "heavy", Hatched = true },
				"junk",
				{ Id = "spiretip", Tier = 2, Hatched = false },
			} })
			check(#mixed.Held == 2 and mixed.Held[1].Id == "nubkin" and mixed.Held[2].Id == "spiretip"
					and mixed.Held[2].Tier == 2 and mixed.Held[2].Hatched == false,
				"what is not a plant is still left at the door: an unknown species, a weight that is not one, "
					.. "a row that is not a row", #mixed.Held)
			check(#schema.Sanitise({ Held = rowsOf(MAX) }).Held == MAX and #schema.Sanitise({}).Held == 0
					and #schema.Sanitise(nil).Held == 0,
				"a save of 24 is the 24 it was, and a save with none has none")
		end
	end

	--==========================================================================
	-- 8b. A ROW WHOSE TOOL HAS GONE
	--
	-- A snapshot may only add to the record, so a Tool the void took -- anything
	-- that is not a sale or a planting -- leaves its row behind until the next
	-- body puts the plant back. A hatch of that same plant at that same size is
	-- a Tool that row already answers for: it IS on the record, the next body
	-- would build exactly it, and it is handed over. Refusing it would be
	-- refusing a hatch that loses nothing.
	--==========================================================================
	say("\n-- a row whose Tool has gone --")
	do
		local v, vPlot, vProfile = w.arrive("VoidTookOne", -612, {
			{ id = "nubkin", tier = 1, ready = true },
			{ id = "nubkin", tier = 1, ready = true },
		}, { { Id = "nubkin", Tier = 1, Hatched = true }, { Id = "petalpip", Tier = 1, Hatched = true } })
		for _, tool in ipairs(plantsOf(v)) do
			if toolKey(tool) == "nubkin:1:true" then
				tool:Destroy()
			end
		end
		task.wait()
		check(#plantsOf(v) == 1 and #vProfile.Held == 2,
			"a Tool the void took leaves its row on the record: one Tool, two rows",
			string.format("%d tools, %d rows", #plantsOf(v), #vProfile.Held))
		local answered, why, payload = w.byHand(v, vPlot, 1)
		check(answered == true and why == nil and payload ~= nil and payload.species == "nubkin",
			"a hatch of that same plant is handed over: the row that was left answers for it",
			tostring(answered) .. " / " .. tostring(why))
		check(#plantsOf(v) == 2 and #vProfile.Held == 2
				and census(vProfile.Held, rowKey) == census(plantsOf(v), toolKey)
				and modelFor(vPlot, 1) == nil and #vProfile.Plants == 1,
			"two Tools and the same two rows, the pod out of the garden: nothing held is off the record",
			string.format("%d tools, %d rows", #plantsOf(v), #vProfile.Held))
		local second = w.byHand(v, vPlot, 2)
		check(second == true and #plantsOf(v) == 3 and #vProfile.Held == 3
				and census(vProfile.Held, rowKey) == census(plantsOf(v), toolKey),
			"and the next one has a row of its own",
			string.format("%d tools, %d rows", #plantsOf(v), #vProfile.Held))
	end

	--==========================================================================
	-- 9. INSTANT HATCH: NO ROOM, NO PURCHASE DIALOG
	--==========================================================================
	say("\n-- instant hatch: the dialog --")
	local buyer, buyerPlot, buyerProfile = w.arrive("Buyer", -608, {
		-- 1: the pod that is paid for; 2: the pod with the longest wait, which is
		-- what a receipt with no note would open; 3: a ready pod.
		{ id = "nubkin", tier = 5, wait = 600 },
		{ id = "petalpip", tier = 1, wait = 9000 },
		{ id = "dunebud", tier = 1, ready = true },
	}, rowsOf(MAX))
	do
		check(pricedPrompt(modelFor(buyerPlot, 1)) and pricedPrompt(modelFor(buyerPlot, 2))
				and (buyerProfile.InstantCredits or 0) == 0,
			"with no Instant Hatch saved, a growing pod's prompt shows its price")
		table.clear(w.prompts)
		local offered = w.PlantService.OfferInstantHatch(buyer, buyerPlot, 1)
		check(offered == false and #w.prompts == 0,
			"with plant storage full, pressing Instant Hatch opens no purchase dialog", #w.prompts)
		check(saidTo(buyer.Name, "STORAGE_FULL") == 1 and saidTo(buyer.Name) == 1,
			"and the player is told PLANT STORAGE FULL", saidTo(buyer.Name))
		w.PlantService.OfferInstantHatch(buyer, buyerPlot, 1)
		w.PlantService.OfferInstantHatch(buyer, buyerPlot, 2)
		check(#w.prompts == 0 and saidTo(buyer.Name) == 1, "pressing again opens nothing and says nothing more")
		w.makeRoom(buyer, 1)
		-- Room, but no record to put a plant on: the save has not arrived. Long
		-- enough after the last line that a new one would be said, were there one.
		task.wait(2.1)
		ready[buyer] = false
		local unknown = w.PlantService.OfferInstantHatch(buyer, buyerPlot, 1)
		ready[buyer] = true
		check(unknown == false and #w.prompts == 0 and saidTo(buyer.Name) == 1,
			"with no record yet, nothing is offered and nothing is said", saidTo(buyer.Name))
		offered = w.PlantService.OfferInstantHatch(buyer, buyerPlot, 1)
		check(offered == true and #w.prompts == 1 and w.prompts[1].who == buyer.Name
				and w.prompts[1].product == SPEC_PRODUCT,
			"with room for one, the press opens the dialog for the Instant Hatch product", #w.prompts)
	end

	--==========================================================================
	-- 10. THE RACE: THE RECORD FILLS AFTER THE DIALOG OPENS
	--==========================================================================
	say("\n-- instant hatch: the record fills before the receipt --")
	do
		-- While the dialog is open, a pod is banked: the last place is taken.
		check(w.CarryService.GivePod(buyer, "spiretip", 1) == true and #buyerProfile.Held == MAX
				and #plantsOf(buyer) == MAX,
			"the dialog is open, and a banked pod takes the last place: 24 of 24")
		task.wait(2.1)
		-- The free prompt on the ready pod, a moment before the receipt: refused
		-- and said, so the receipt's own line is asked for inside the quiet time.
		w.byHand(buyer, buyerPlot, 3)
		local asked = os.time()
		local saidBefore, savesBefore = saidTo(buyer.Name), savesOf(buyer.Name)
		local rowsBefore = census(buyerProfile.Held, rowKey)
		local gardenBefore = gardenWrites(buyer.Name)
		local waitBefore = rowFor(buyerProfile, "nubkin", 5)
		local otherBefore = rowFor(buyerProfile, "petalpip", 1)
		check(waitBefore ~= nil and waitBefore.HatchAt > asked + 60 and stillGrowing(buyerPlot, 1)
				and otherBefore ~= nil and stillGrowing(buyerPlot, 2),
			"the pod that is being paid for is still growing, and so is the one beside it")
		local otherDeadline = otherBefore and otherBefore.HatchAt

		local decision, payload = w.deliver(buyer, "spec-race-1")
		check(decision == GRANTED, "the receipt IS acknowledged: the purchase did what it could",
			tostring(decision))
		check(payload == nil and #plantsOf(buyer) == MAX and #buyerProfile.Held == MAX
				and census(buyerProfile.Held, rowKey) == rowsBefore
				and census(plantsOf(buyer), toolKey) == rowsBefore,
			"no plant is handed over and none is announced: the hatch itself is refused, as any is",
			string.format("%d tools, %d rows", #plantsOf(buyer), #buyerProfile.Held))
		local model = modelFor(buyerPlot, 1)
		check(model ~= nil and podsIn(buyerPlot) == 3 and w.PlantService.CountIn(buyerPlot) == 3
				and stillReady(buyerPlot, 1) and promptsOn(model, "InstantHatchPrompt") == 0,
			"THE POD THAT WAS PAID FOR IS READY NOW: still planted, the free prompt on it, the paid one gone")
		local row = rowFor(buyerProfile, "nubkin", 5)
		check(row ~= nil and row.Stage == 1 and row.HatchAt >= asked and row.HatchAt <= os.time()
				and model ~= nil and model:GetAttribute("HatchAt") == row.HatchAt
				and #buyerProfile.Plants == 3 and gardenWrites(buyer.Name) == gardenBefore + 1,
			"its wait is over in the saved garden too: one deadline, on the pod and on the record",
			row and string.format("%d against %d", row.HatchAt, asked))
		local other = rowFor(buyerProfile, "petalpip", 1)
		check(other ~= nil and other.HatchAt == otherDeadline and stillGrowing(buyerPlot, 2)
				and stillReady(buyerPlot, 3),
			"no other pod is touched: the one beside it goes on growing")
		local save, garden = lastSave(buyer.Name), lastGardenWrite(buyer.Name)
		check(#buyerProfile.Receipts == 1 and buyerProfile.Receipts[1] == "spec-race-1"
				and savesOf(buyer.Name) == savesBefore + 1 and save ~= nil and save.worked == true
				and #save.receipts == 1 and save.receipts[1] == "spec-race-1"
				and row ~= nil and save.deadlines["nubkin:5"] == row.HatchAt
				and garden ~= nil and garden.at < save.at,
			"ACKNOWLEDGED ONLY ONCE RECORDED: the save that was answered for holds the purchase and the "
				.. "pod's new deadline, and the garden was written before it",
			save and string.format("%d receipts, deadline %s", #save.receipts, tostring(save.deadlines["nubkin:5"])))
		check(saidTo(buyer.Name, "STORAGE_FULL_READY") == 1 and saidTo(buyer.Name) == saidBefore + 1
				and saidTo(buyer.Name, "STORAGE_FULL_CREDIT") == 0 and (buyerProfile.InstantCredits or 0) == 0,
			"the buyer is told, a moment after another line: storage full, and the pod is ready to hatch "
				.. "free once there is room", saidTo(buyer.Name) - saidBefore)

		-- Delivered again, as Roblox may: with the record still full.
		local again, againPayload = w.deliver(buyer, "spec-race-1")
		check(again == GRANTED and againPayload == nil and #buyerProfile.Receipts == 1
				and gardenWrites(buyer.Name) == gardenBefore + 1 and saidTo(buyer.Name) == saidBefore + 1
				and stillGrowing(buyerPlot, 2) and rowFor(buyerProfile, "petalpip", 1).HatchAt == otherDeadline
				and #plantsOf(buyer) == MAX and #buyerProfile.Held == MAX,
			"delivered again: acknowledged, nothing more made ready, nothing more said -- paid once, given once",
			tostring(again))

		-- Still full: the ready pod is a ready pod like any other.
		task.wait(2.1)
		local full, fullWhy = w.byHand(buyer, buyerPlot, 1)
		check(full == false and fullWhy == "STORAGE_FULL" and stillReady(buyerPlot, 1)
				and saidTo(buyer.Name, "STORAGE_FULL") >= 1 and #plantsOf(buyer) == MAX,
			"with the record still full it is refused by hand like any ready pod, and stays",
			tostring(full) .. " / " .. tostring(fullWhy))

		-- Room is made, and it hatches for nothing.
		local promptsBefore = #w.prompts
		w.makeRoom(buyer, 1)
		local yes, yesWhy, freePayload = w.byHand(buyer, buyerPlot, 1)
		check(yes == true and yesWhy == nil and freePayload ~= nil and freePayload.species == "nubkin"
				and freePayload.tier == 5 and freePayload.paid ~= true,
			"once there is room THE POD THAT WAS PAID FOR hatches by hand, for nothing",
			tostring(yes) .. " / " .. tostring(yesWhy))
		check(#plantsOf(buyer) == MAX and #buyerProfile.Held == MAX
				and countKey(buyerProfile.Held, rowKey, "nubkin:5:true") == 1
				and countKey(plantsOf(buyer), toolKey, "nubkin:5:true") == 1
				and modelFor(buyerPlot, 1) == nil and modelFor(buyerPlot, 2) ~= nil and podsIn(buyerPlot) == 2
				and #buyerProfile.Plants == 2,
			"one plant, one row, that pod out of the garden and the others in it",
			string.format("%d tools, %d rows, %d pods", #plantsOf(buyer), #buyerProfile.Held, podsIn(buyerPlot)))
		check(#w.prompts == promptsBefore and #buyerProfile.Receipts == 1,
			"no second purchase was asked for, and the ledger holds the one")

		-- And once more, after the hatch.
		local fourth, fourthPayload = w.deliver(buyer, "spec-race-1")
		check(fourth == GRANTED and fourthPayload == nil and #plantsOf(buyer) == MAX
				and #buyerProfile.Held == MAX and podsIn(buyerPlot) == 2 and #buyerProfile.Receipts == 1
				and stillGrowing(buyerPlot, 2),
			"a further delivery of the same receipt is acknowledged and changes nothing",
			tostring(fourth))
	end

	--==========================================================================
	-- 10b. THE POD THAT WAS MADE READY, THROUGH A DEATH AND A REJOIN
	--==========================================================================
	say("\n-- instant hatch: the ready pod, a death and a rejoin --")
	do
		local r, rPlot, rProfile = w.arrive("PaidThenLeaves", -613, {
			{ id = "bellchime", tier = 4, wait = 700 },
			{ id = "petalpip", tier = 2, wait = 9000 },
		}, rowsOf(MAX - 1))
		check(w.PlantService.OfferInstantHatch(r, rPlot, 1) == true and stillGrowing(rPlot, 1),
			"a purchase dialog opens, with room for one")
		w.CarryService.GivePod(r, "spiretip", 1)
		task.wait()
		local decision, payload = w.deliver(r, "spec-leave-1")
		local row = rowFor(rProfile, "bellchime", 4)
		local deadline = row and row.HatchAt
		check(decision == GRANTED and payload == nil and stillReady(rPlot, 1) and #rProfile.Held == MAX
				and #plantsOf(r) == MAX and deadline ~= nil and deadline <= os.time()
				and #rProfile.Receipts == 1,
			"the record filled first: the pod is made ready, and the purchase acknowledged",
			tostring(decision))
		local rowsBefore = census(rProfile.Held, rowKey)

		die(w, r)
		check(#plantsOf(r) == MAX and #rProfile.Held == MAX and census(rProfile.Held, rowKey) == rowsBefore
				and census(plantsOf(r), toolKey) == rowsBefore,
			"after a death the 24 are rebuilt: nothing lost, nothing made",
			string.format("%d tools, %d rows", #plantsOf(r), #rProfile.Held))
		check(stillReady(rPlot, 1) and stillGrowing(rPlot, 2) and podsIn(rPlot) == 2
				and rowFor(rProfile, "bellchime", 4).HatchAt == deadline,
			"and the pod is still planted and still ready: a death does not touch a garden")

		leave(w, r)
		local left = rowFor(rProfile, "bellchime", 4)
		check(#rProfile.Held == MAX and census(rProfile.Held, rowKey) == rowsBefore and #rProfile.Plants == 2
				and left ~= nil and left.HatchAt == deadline and left.Stage == 1
				and #rProfile.Receipts == 1 and rProfile.Receipts[1] == "spec-leave-1",
			"the save they leave with has the 24, the pod with its wait over, and the purchase",
			string.format("%d rows, %d pods, %d receipts", #rProfile.Held, #rProfile.Plants, #rProfile.Receipts))

		local back, backPlot = w.arrive("PaidThenLeaves", -613, nil, nil, rProfile)
		local readyId = idWithDeadline(backPlot, deadline)
		local growingRow = rowFor(rProfile, "petalpip", 2)
		local growingId = growingRow and idWithDeadline(backPlot, growingRow.HatchAt)
		check(#plantsOf(back) == MAX and #rProfile.Held == MAX and census(rProfile.Held, rowKey) == rowsBefore
				and podsIn(backPlot) == 2 and readyId ~= nil and stillReady(backPlot, readyId)
				and promptsOn(modelFor(backPlot, readyId), "InstantHatchPrompt") == 0
				and growingId ~= nil and stillGrowing(backPlot, growingId),
			"they come back to the 24 and to the pod THEY PAID FOR, ready, with the free prompt on it",
			string.format("%d tools, %d rows, ready pod %s", #plantsOf(back), #rProfile.Held, tostring(readyId)))

		-- Roblox delivers a receipt again when the player next joins.
		local gardenBefore, saidBefore = gardenWrites(back.Name), saidTo(back.Name)
		local again, againPayload = w.deliver(back, "spec-leave-1")
		check(again == GRANTED and againPayload == nil and #rProfile.Receipts == 1
				and gardenWrites(back.Name) == gardenBefore and saidTo(back.Name) == saidBefore
				and growingId ~= nil and stillGrowing(backPlot, growingId)
				and #plantsOf(back) == MAX and #rProfile.Held == MAX,
			"the receipt delivered again after the rejoin is acknowledged, and makes nothing else ready",
			tostring(again))

		local no, noWhy = w.byHand(back, backPlot, readyId or 0)
		check(no == false and noWhy == "STORAGE_FULL" and readyId ~= nil and stillReady(backPlot, readyId),
			"still full: still refused by hand, still planted and ready")
		w.makeRoom(back, 1)
		local yes, _, freePayload = w.byHand(back, backPlot, readyId or 0)
		check(yes == true and freePayload ~= nil and freePayload.species == "bellchime"
				and freePayload.tier == 4 and freePayload.paid ~= true
				and #plantsOf(back) == MAX and #rProfile.Held == MAX
				and countKey(rProfile.Held, rowKey, "bellchime:4:true") == 1 and podsIn(backPlot) == 1,
			"and with room it hatches for nothing: the plant that was paid for, once",
			string.format("%s, %d tools, %d rows", tostring(yes), #plantsOf(back), #rProfile.Held))
	end

	--==========================================================================
	-- 10c. NOTHING TO END: ONE CREDIT, SAVED BEFORE THE RECEIPT IS ANSWERED
	--
	-- The one purchase that finds nothing it can do: the record full AND the pod
	-- it was bought for ready already (its own clock ran out while the dialog
	-- was open). The owner's decision, 2026-09-30: "save one credit for that
	-- purchase, acknowledge the receipt only after the credit is safely saved,
	-- and make sure a duplicate receipt can't add a second credit. The credit
	-- should only be used when an eligible hatch actually succeeds."
	--==========================================================================
	say("\n-- instant hatch: no room, and no wait left to end: one credit --")
	do
		local c, cPlot, cProfile = w.arrive("ClockRanOut", -614, {
			{ id = "toadcap", tier = 3, wait = 3 },
			{ id = "petalpip", tier = 1, ready = true },
			{ id = "bellchime", tier = 2, wait = 5000 },
			{ id = "nubkin", tier = 2, wait = 6000 },
		}, rowsOf(MAX - 1))
		local offered = w.PlantService.OfferInstantHatch(c, cPlot, 1)
		check(offered == true, "a purchase dialog opens for a pod with seconds to go", tostring(offered))
		w.CarryService.GivePod(c, "spiretip", 1)
		task.wait(4.5)
		check(stillReady(cPlot, 1) and #cProfile.Held == MAX and stillGrowing(cPlot, 3) and stillGrowing(cPlot, 4),
			"while it is open the pod's own clock runs out, and the record fills")
		-- The free prompt on the other ready pod, a moment before the receipt:
		-- refused and said, so the receipt's own line comes inside the quiet time.
		w.byHand(c, cPlot, 2)
		local deadline = rowFor(cProfile, "toadcap", 3).HatchAt
		local growingDeadline = rowFor(cProfile, "bellchime", 2).HatchAt
		local gardenBefore, savesBefore, saidBefore = gardenWrites(c.Name), savesOf(c.Name), saidTo(c.Name)
		local decision, payload = w.deliver(c, "spec-corner-1")
		check(decision == GRANTED and payload == nil,
			"the receipt IS acknowledged: the purchase is kept for later", tostring(decision))
		local save = lastSave(c.Name)
		check(cProfile.InstantCredits == 1 and savesOf(c.Name) == savesBefore + 1 and save ~= nil
				and save.worked == true and save.credits == 1 and #save.receipts == 1
				and save.receipts[1] == "spec-corner-1",
			"ONE credit, and the save that was answered for holds it beside the purchase in the ledger",
			save and string.format("%s credits, %d receipts", tostring(save.credits), #save.receipts))
		check(gardenWrites(c.Name) == gardenBefore and rowFor(cProfile, "toadcap", 3).HatchAt == deadline
				and rowFor(cProfile, "bellchime", 2).HatchAt == growingDeadline
				and stillReady(cPlot, 1) and stillReady(cPlot, 2) and stillGrowing(cPlot, 3)
				and stillGrowing(cPlot, 4) and podsIn(cPlot) == 4 and #plantsOf(c) == MAX and #cProfile.Held == MAX,
			"nothing else is changed: no pod hatched or made ready, the garden not rewritten, 24 of 24")
		check(saidTo(c.Name, "STORAGE_FULL_CREDIT") == 1 and saidTo(c.Name) == saidBefore + 1,
			"the buyer is told the Instant Hatch is saved for later, even a moment after another line")
		check(freePrompt(modelFor(cPlot, 3)) and freePrompt(modelFor(cPlot, 4)),
			"their growing pods' Instant Hatch prompts show no price now: FREE INSTANT HATCH")

		-- Delivered again, as Roblox may.
		local again, againPayload = w.deliver(c, "spec-corner-1")
		check(again == GRANTED and againPayload == nil and cProfile.InstantCredits == 1
				and #cProfile.Receipts == 1 and saidTo(c.Name) == saidBefore + 1,
			"a duplicate delivery of the same receipt adds no second credit and says nothing", tostring(again))

		-- Still full: the credit cannot buy anything, and is not touched.
		task.wait(2.1)
		local full, fullPayload, fullDialogs = w.offer(c, cPlot, 3)
		check(full == false and fullPayload == nil and fullDialogs == 0 and cProfile.InstantCredits == 1
				and stillGrowing(cPlot, 3) and saidTo(c.Name, "STORAGE_FULL") >= 1,
			"with the record still full, pressing it opens no purchase and leaves the credit where it was")
		-- A ready pod hatches for free on E: it is not what a credit is for.
		local readyPress = w.offer(c, cPlot, 2)
		check(readyPress == false and cProfile.InstantCredits == 1 and stillReady(cPlot, 2),
			"a pod that is ready already does not take the credit")

		-- Room is made: the next press hatches for the credit.
		w.makeRoom(c, 1)
		local used, usedPayload, usedDialogs = w.offer(c, cPlot, 3)
		check(used == true and usedDialogs == 0 and usedPayload ~= nil and usedPayload.species == "bellchime"
				and usedPayload.tier == 2,
			"with room, the press hatches THAT pod, and opens no purchase dialog",
			tostring(used) .. " / " .. tostring(usedDialogs))
		check(cProfile.InstantCredits == 0 and #plantsOf(c) == MAX and #cProfile.Held == MAX
				and countKey(cProfile.Held, rowKey, "bellchime:2:true") == 1 and modelFor(cPlot, 3) == nil
				and #cProfile.Plants == 3,
			"the credit is spent only now, with the hatch: one plant, one row, the pod out of the garden",
			string.format("%s credits, %d rows", tostring(cProfile.InstantCredits), #cProfile.Held))
		check(saidTo(c.Name, "INSTANT_CREDIT_USED") == 1, "the player is told the saved Instant Hatch was used")
		check(pricedPrompt(modelFor(cPlot, 4)), "and with none left, the other pod's prompt shows its price again")

		-- With no credit, the next press asks for a purchase again.
		w.makeRoom(c, 1)
		task.wait(1.1)
		local sold, soldPayload, soldDialogs = w.offer(c, cPlot, 4)
		check(sold == true and soldDialogs == 1 and soldPayload == nil and stillGrowing(cPlot, 4)
				and cProfile.InstantCredits == 0,
			"with no credit left, pressing Instant Hatch opens the purchase dialog as before")
	end

	--==========================================================================
	-- 10d. A RECEIPT WITH NO NOTE: A LATER SESSION (2026-09-30, the owner's rule)
	--
	-- Delivered after a rejoin there is no note of which pod was pressed. The
	-- owner's decision: "If the selected pod is gone or its target cannot be
	-- established safely, save a credit" -- no pod is picked in its place. It
	-- used to open the pod with the longest wait, and with the record full make
	-- that pod ready.
	--==========================================================================
	say("\n-- instant hatch: a receipt from an earlier session, with the record full --")
	do
		local n, nPlot, nProfile = w.arrive("NoNote", -615, {
			{ id = "dunebud", tier = 2, wait = 400 },
			{ id = "spiretip", tier = 3, wait = 7000 },
			{ id = "nubkin", tier = 1, ready = true },
		}, rowsOf(MAX))
		local short = rowFor(nProfile, "dunebud", 2).HatchAt
		local long = rowFor(nProfile, "spiretip", 3).HatchAt
		local decision, payload = w.deliver(n, "spec-nonote-1")
		check(decision == GRANTED and payload == nil and nProfile.InstantCredits == 1
				and stillGrowing(nPlot, 1) and stillGrowing(nPlot, 2)
				and rowFor(nProfile, "dunebud", 2).HatchAt == short and rowFor(nProfile, "spiretip", 3).HatchAt == long
				and #nProfile.Receipts == 1 and #plantsOf(n) == MAX and #nProfile.Held == MAX
				and saidTo(n.Name, "STORAGE_FULL_CREDIT") == 1 and saidTo(n.Name, "STORAGE_FULL_READY") == 0,
			"with no note nothing is made ready: ONE credit, acknowledged, and the storage-full line",
			tostring(decision))
		local second = w.deliver(n, "spec-nonote-2")
		local third = w.deliver(n, "spec-nonote-3")
		check(second == GRANTED and third == GRANTED and #nProfile.Receipts == 3 and nProfile.InstantCredits == 3
				and stillGrowing(nPlot, 1) and stillGrowing(nPlot, 2) and podsIn(nPlot) == 3
				and #plantsOf(n) == MAX and #nProfile.Held == MAX,
			"two more purchases are two more credits, and still no pod is picked for them",
			tostring(second) .. " / " .. tostring(third))
	end

	--==========================================================================
	-- 10e. THE CREDIT'S EDGES
	--
	-- A profile that can never be saved is given no credit; a save that fails
	-- leaves the receipt open without a second credit on the next delivery; a
	-- credit past the cap is not granted; a hatch refused after all keeps the
	-- credit; and a credit outlives a death, a leave and a rejoin.
	--==========================================================================
	say("\n-- instant hatch: the credit's edges --")
	do
		-- Every pod ready and the record full: a receipt finds nothing to end.
		local e, ePlot, eProfile = w.arrive("CreditEdges", -619, {
			{ id = "nubkin", tier = 1, ready = true },
		}, rowsOf(MAX))
		local gardenBefore = gardenWrites(e.Name)

		temporary[e] = true
		local notKept = w.deliver(e, "spec-edge-1")
		temporary[e] = nil
		check(notKept == RETRY and eProfile.InstantCredits == 0 and #eProfile.Receipts == 0
				and saidTo(e.Name) == 0 and stillReady(ePlot, 1),
			"a profile that can never be saved is given no credit: the receipt stays open", tostring(notKept))

		saveFails[e] = true
		local first = w.deliver(e, "spec-edge-2")
		check(first == RETRY and eProfile.InstantCredits == 1 and #eProfile.Receipts == 1,
			"the credit is added, the save fails, and the receipt is NOT acknowledged", tostring(first))
		local second = w.deliver(e, "spec-edge-2")
		check(second == RETRY and eProfile.InstantCredits == 1 and #eProfile.Receipts == 1
				and saidTo(e.Name, "STORAGE_FULL_CREDIT") == 1,
			"delivered again with the save still failing: not acknowledged, and no second credit", tostring(second))
		saveFails[e] = nil
		local third = w.deliver(e, "spec-edge-2")
		local save = lastSave(e.Name)
		check(third == GRANTED and eProfile.InstantCredits == 1 and save ~= nil and save.worked == true
				and save.credits == 1 and save.receipts[1] == "spec-edge-2",
			"acknowledged once a save holding the credit and the purchase has been written: one purchase, one credit",
			tostring(third))

		eProfile.InstantCredits = GameConfig.Save.MaxInstantCredits
		local capped = w.deliver(e, "spec-edge-3")
		check(capped == RETRY and eProfile.InstantCredits == GameConfig.Save.MaxInstantCredits
				and #eProfile.Receipts == 1,
			"a credit past the cap is not granted: the receipt stays open", tostring(capped))
		eProfile.InstantCredits = 1
		check(gardenWrites(e.Name) == gardenBefore and stillReady(ePlot, 1) and #plantsOf(e) == MAX,
			"none of it touches the garden or the bag")

		-- The credit is that purchase's, and its note goes with it: the next
		-- receipt, with no dialog opened for it, names no pod, and is a credit of
		-- its own -- the growing pod is not picked in its place (2026-09-30).
		local s, sPlot, sProfile = w.arrive("NoteSpent", -621, {
			{ id = "toadcap", tier = 2, wait = 3 },
			{ id = "dunebud", tier = 3, wait = 7000 },
		}, rowsOf(MAX - 1))
		check(w.PlantService.OfferInstantHatch(s, sPlot, 1) == true, "(a dialog opens for a pod with seconds to go)")
		w.CarryService.GivePod(s, "spiretip", 1)
		task.wait(4.5)
		local kept = w.deliver(s, "spec-note-1")
		check(kept == GRANTED and sProfile.InstantCredits == 1 and stillReady(sPlot, 1) and stillGrowing(sPlot, 2),
			"its pod's clock ran out and the record filled: kept as one credit", tostring(kept))
		local nextOne = w.deliver(s, "spec-note-2")
		check(nextOne == GRANTED and sProfile.InstantCredits == 2 and stillGrowing(sPlot, 2)
				and saidTo(s.Name, "STORAGE_FULL_READY") == 0,
			"the next purchase, with no note, is a second credit: the growing pod is not made ready for it",
			tostring(nextOne))

		-- A player holding one credit, with room, and two growing pods.
		local h, hPlot, hProfile = w.arrive("CreditHolder", -620, nil, nil, {
			Plants = gardenOf({ { id = "nubkin", tier = 3, wait = 5000 }, { id = "petalpip", tier = 2, wait = 6000 } }),
			Held = rowsOf(10), Almanac = {}, Receipts = {}, InstantCredits = 1 })
		check(freePrompt(modelFor(hPlot, 1)) and freePrompt(modelFor(hPlot, 2)),
			"a garden restored for a player holding a credit shows FREE INSTANT HATCH on every growing pod")

		heldFails[h] = true
		local refused, refusedPayload, refusedDialogs = w.offer(h, hPlot, 1)
		heldFails[h] = nil
		task.wait()
		check(refused == false and refusedPayload == nil and refusedDialogs == 0 and hProfile.InstantCredits == 1
				and stillGrowing(hPlot, 1) and #plantsOf(h) == 10,
			"a hatch the record refuses after all (NOT_RECORDED): nothing hatched, the credit kept, no dialog")
		ready[h] = false
		local noRecord, _, noRecordDialogs = w.offer(h, hPlot, 1)
		ready[h] = true
		check(noRecord == false and noRecordDialogs == 0 and hProfile.InstantCredits == 1 and stillGrowing(hPlot, 1),
			"no record at all: nothing hatched, the credit kept, no dialog")

		die(w, h)
		check(hProfile.InstantCredits == 1 and #plantsOf(h) == 10 and freePrompt(modelFor(hPlot, 1)),
			"a death leaves the credit, and the prompt still says it is free")
		leave(w, h)
		check(hProfile.InstantCredits == 1, "the save they leave with holds the credit")
		local back, backPlot = w.arrive("CreditHolder", -620, nil, nil, hProfile)
		check(freePrompt(modelFor(backPlot, 1)) and freePrompt(modelFor(backPlot, 2)),
			"they come back to the credit, and to FREE INSTANT HATCH on their growing pods")
		local used, usedPayload, usedDialogs = w.offer(back, backPlot, 1)
		check(used == true and usedDialogs == 0 and usedPayload ~= nil and hProfile.InstantCredits == 0
				and #plantsOf(back) == 11 and #hProfile.Held == 11 and pricedPrompt(modelFor(backPlot, 2)),
			"after the rejoin the credit hatches a pod with no dialog, and is gone: the other prompt shows its price",
			string.format("%s / %s credits", tostring(used), tostring(hProfile.InstantCredits)))
	end

	--==========================================================================
	-- 10f. NO UNHATCHED POD: ONE CREDIT PER PURCHASE (2026-09-30)
	--
	-- The owner's decision: "if a paid receipt arrives and the player has no
	-- unhatched pod, grant one saved Instant Hatch credit" -- saved before the
	-- purchase is acknowledged, never twice for one receipt, the receipt left
	-- open if the save fails, separate purchases separate credits. A receipt
	-- that arrives before the garden is in the world at all (the profile has
	-- loaded, the player has no plot yet) has no pod it can reach either.
	--==========================================================================
	say("\n-- instant hatch: no unhatched pod: one credit per purchase --")
	do
		-- A grown plant and no pod, room on the record: nothing a receipt can hatch.
		local g, gPlot, gProfile = w.arrive("NoPodAtAll", -622, {
			{ id = "nubkin", tier = 2, grown = true },
		}, rowsOf(5))
		local gardenBefore, savesBefore = gardenWrites(g.Name), savesOf(g.Name)
		local first, firstPayload = w.deliver(g, "spec-nopod-1")
		local save = lastSave(g.Name)
		check(first == GRANTED and firstPayload == nil and gProfile.InstantCredits == 1
				and savesOf(g.Name) == savesBefore + 1 and save ~= nil and save.worked == true
				and save.credits == 1 and #save.receipts == 1 and save.receipts[1] == "spec-nopod-1",
			"no unhatched pod: ONE credit, and the save that was answered for holds it beside the purchase",
			tostring(first))
		check(gardenWrites(g.Name) == gardenBefore and #gProfile.Plants == 1 and modelFor(gPlot, 1) ~= nil
				and #plantsOf(g) == 5 and #gProfile.Held == 5,
			"nothing else moves: the grown plant stays, the bag and the record are what they were")
		check(saidTo(g.Name, "INSTANT_CREDIT_NO_POD") == 1 and saidTo(g.Name) == 1,
			"the buyer is told the Instant Hatch is saved for later")
		local again = w.deliver(g, "spec-nopod-1")
		check(again == GRANTED and gProfile.InstantCredits == 1 and #gProfile.Receipts == 1 and saidTo(g.Name) == 1,
			"a duplicate delivery of that receipt adds no second credit and says nothing", tostring(again))
		local second = w.deliver(g, "spec-nopod-2")
		check(second == GRANTED and gProfile.InstantCredits == 2 and #gProfile.Receipts == 2
				and saidTo(g.Name, "INSTANT_CREDIT_NO_POD") == 2,
			"a second, separate purchase is a second credit", tostring(second))

		-- The save does not reach the disk: open, and no second credit on the retry.
		saveFails[g] = true
		local failing = w.deliver(g, "spec-nopod-3")
		local stillFailing = w.deliver(g, "spec-nopod-3")
		check(failing == RETRY and stillFailing == RETRY and gProfile.InstantCredits == 3
				and #gProfile.Receipts == 3,
			"a save that fails leaves the receipt open, and delivered again it adds nothing",
			tostring(failing) .. " / " .. tostring(stillFailing))
		saveFails[g] = nil
		local landed = w.deliver(g, "spec-nopod-3")
		local landedSave = lastSave(g.Name)
		check(landed == GRANTED and gProfile.InstantCredits == 3 and landedSave ~= nil and landedSave.credits == 3
				and landedSave.receipts[3] == "spec-nopod-3",
			"acknowledged once a save holding it has been written: three purchases, three credits", tostring(landed))

		-- A profile that can never be saved: none.
		temporary[g] = true
		local unsaved = w.deliver(g, "spec-nopod-4")
		temporary[g] = nil
		check(unsaved == RETRY and gProfile.InstantCredits == 3 and #gProfile.Receipts == 3,
			"a profile that can never be saved is given no credit: the receipt stays open", tostring(unsaved))

		-- The profile has arrived and the garden has not: no plot yet.
		local early, assign = w.arriveWithoutPlot("NotPlantedYet", -623, {
			Plants = gardenOf({ { id = "petalpip", tier = 3, wait = 6000 } }), Held = rowsOf(4), Almanac = {},
			Receipts = {}, InstantCredits = 0 })
		local earlyDecision, earlyPayload = w.deliver(early, "spec-early-1")
		check(earlyDecision == GRANTED and earlyPayload == nil and profiles[early].InstantCredits == 1
				and saidTo(early.Name, "INSTANT_CREDIT_NO_POD") == 1,
			"before the garden is in the world there is no pod it can reach: one credit, not a receipt left open",
			tostring(earlyDecision))
		local earlyPlot = assign()
		check(stillGrowing(earlyPlot, 1) and freePrompt(modelFor(earlyPlot, 1)) and profiles[early].InstantCredits == 1,
			"when the garden comes back, its growing pod shows FREE INSTANT HATCH")
		local spent, spentPayload, spentDialogs = w.offer(early, earlyPlot, 1)
		check(spent == true and spentDialogs == 0 and spentPayload ~= nil and spentPayload.species == "petalpip"
				and profiles[early].InstantCredits == 0,
			"and the credit hatches it, with no purchase dialog", tostring(spent))

		-- Two credits: one spent leaves one, and the prompt stays free.
		local two, twoPlot, twoProfile = w.arrive("TwoCredits", -624, nil, nil, {
			Plants = gardenOf({ { id = "nubkin", tier = 3, wait = 5000 }, { id = "dunebud", tier = 2, wait = 6000 } }),
			Held = rowsOf(6), Almanac = {}, Receipts = {}, InstantCredits = 2 })
		local once = w.offer(two, twoPlot, 1)
		check(once == true and twoProfile.InstantCredits == 1 and freePrompt(modelFor(twoPlot, 2)),
			"with two credits, one hatch spends one: the other pod's prompt is still free")
		local twice = w.offer(two, twoPlot, 2)
		check(twice == true and twoProfile.InstantCredits == 0 and #plantsOf(two) == 8,
			"and the second hatch spends the second: none left")
	end

	--==========================================================================
	-- 10g. A CREDIT, WHATEVER THE PRODUCT'S STATE (2026-09-30, found in review)
	--
	-- A saved Instant Hatch was paid for. Taking the product off sale (its id
	-- back to 0) used to hide every Instant Hatch prompt and refuse every press
	-- before the credit was asked about -- the credit stranded. Now a credit
	-- holder is shown the free prompt and the press spends it, and nothing is
	-- sold: no price, no dialog.
	--==========================================================================
	say("\n-- instant hatch: a credit with the product off sale --")
	do
		local liveId = w.hatchItem.product
		w.hatchItem.product = 0
		local ok, err = pcall(function()
			local c, cPlot, cProfile = w.arrive("OffSaleCredit", -625, nil, nil, {
				Plants = gardenOf({ { id = "nubkin", tier = 3, wait = 5000 }, { id = "dunebud", tier = 2, wait = 6000 } }),
				Held = rowsOf(6), Almanac = {}, Receipts = {}, InstantCredits = 1 })
			check(freePrompt(modelFor(cPlot, 1)) and freePrompt(modelFor(cPlot, 2)),
				"with the product off sale, a credit holder's growing pods still show FREE INSTANT HATCH")
			local spent, payload, dialogs = w.offer(c, cPlot, 1)
			check(spent == true and dialogs == 0 and payload ~= nil and payload.species == "nubkin"
					and cProfile.InstantCredits == 0 and #cProfile.Held == 7,
				"and the press spends it: the pod hatches, no purchase dialog", tostring(spent))
			check(instantPromptOn(modelFor(cPlot, 2)) == nil,
				"with the last credit gone and nothing on sale, the other pod's prompt goes: nothing to press")

			local n, nPlot = w.arrive("OffSaleNoCredit", -626, { { id = "petalpip", tier = 3, wait = 5000 } }, rowsOf(4))
			local refused, _, noDialogs = w.offer(n, nPlot, 1)
			check(instantPromptOn(modelFor(nPlot, 1)) == nil and refused == false and noDialogs == 0,
				"with no credit and nothing on sale: no prompt, and a press opens nothing", tostring(refused))
		end)
		w.hatchItem.product = liveId
		check(ok, "the off-sale section ran to the end", err)
	end

	--==========================================================================
	-- 10h. EVERY POD ALREADY READY: A CREDIT, NOT A HATCH (2026-09-30)
	--
	-- The owner's option B: "For an unresolved Instant Hatch receipt, if no pod
	-- still has time left, save one Instant Hatch credit instead of hatching a
	-- ready pod. Keep the existing duplicate-receipt protection: a receipt
	-- already fulfilled must not grant a credit as well." A receipt with room
	-- used to hatch the pod that became ready most recently.
	--==========================================================================
	say("\n-- instant hatch: every pod already ready --")
	do
		local r, rPlot, rProfile = w.arrive("AllReady", -627, {
			{ id = "nubkin", tier = 2, ready = true },
			{ id = "dunebud", tier = 3, ready = true },
		}, rowsOf(5))
		local toolsBefore = #plantsOf(r)
		local first, firstPayload = w.deliver(r, "spec-ready-1")
		local save = lastSave(r.Name)
		check(first == GRANTED and firstPayload == nil and rProfile.InstantCredits == 1
				and save ~= nil and save.worked == true and save.credits == 1 and #save.receipts == 1
				and save.receipts[1] == "spec-ready-1",
			"every pod already ready, with room: ONE credit, saved beside the purchase before it is answered for",
			tostring(first))
		check(modelFor(rPlot, 1) ~= nil and modelFor(rPlot, 2) ~= nil and #plantsOf(r) == toolsBefore
				and #rProfile.Held == 5 and #rProfile.Plants == 2,
			"and no ready pod is hatched: both still planted, nothing handed over")
		check(saidTo(r.Name, "INSTANT_CREDIT_READY") == 1 and saidTo(r.Name) == 1,
			"the buyer is told their pods are ready and the Instant Hatch is saved")
		local again = w.deliver(r, "spec-ready-1")
		check(again == GRANTED and rProfile.InstantCredits == 1 and #rProfile.Receipts == 1 and saidTo(r.Name) == 1,
			"a duplicate delivery of that receipt adds no second credit and says nothing", tostring(again))
		saveFails[r] = true
		local failing = w.deliver(r, "spec-ready-2")
		local stillFailing = w.deliver(r, "spec-ready-2")
		saveFails[r] = nil
		local landed = w.deliver(r, "spec-ready-2")
		check(failing == RETRY and stillFailing == RETRY and landed == GRANTED and rProfile.InstantCredits == 2
				and #rProfile.Receipts == 2,
			"a save that fails leaves the receipt open, the retry adds nothing, and it is answered for once saved")
		check(#rProfile.Plants == 2 and modelFor(rPlot, 1) ~= nil, "and still no ready pod was hatched")

		-- A RECEIPT ALREADY FULFILLED: a pod still counting down was hatched for
		-- it. Delivered again once every pod left is ready, the ledger answers it.
		local f, fPlot, fProfile = w.arrive("FulfilledThenReady", -628, {
			{ id = "petalpip", tier = 3, wait = 5000 },
			{ id = "nubkin", tier = 1, ready = true },
		}, rowsOf(4))
		check(w.PlantService.OfferInstantHatch(f, fPlot, 1) == true, "(the growing pod is pressed)")
		local paid, paidPayload = w.deliver(f, "spec-done-1")
		check(paid == GRANTED and paidPayload ~= nil and paidPayload.species == "petalpip"
				and fProfile.InstantCredits == 0 and modelFor(fPlot, 2) ~= nil,
			"with a pod still counting down, the receipt hatches it and leaves the ready pod alone", tostring(paid))
		local redelivered = w.deliver(f, "spec-done-1")
		check(redelivered == GRANTED and fProfile.InstantCredits == 0 and #fProfile.Receipts == 1
				and modelFor(fPlot, 2) ~= nil and saidTo(f.Name, "INSTANT_CREDIT_READY") == 0,
			"delivered again now that every pod left is ready: already fulfilled, so no credit as well",
			tostring(redelivered))
	end

	--==========================================================================
	-- 10i. THE POD THAT WAS PRESSED, AND ONLY THAT POD (2026-09-30)
	--
	-- The owner's decision: "the purchase is for the pod the player pressed. If
	-- that pod becomes ready while the purchase dialog is open, save one Instant
	-- Hatch credit -- even if other pods are still growing. Do not use the
	-- purchase to hatch an already-ready pod or silently switch it to another
	-- pod. If the selected pod is gone or its target cannot be established
	-- safely, save a credit. Keep the approved behavior when the selected pod is
	-- still growing, including the full-storage case." With the safeguards: a
	-- fulfilled receipt gives nothing more, a credit and its receipt are saved
	-- before the purchase is answered for, and a failed save leaves it open.
	-- (The pressed pod still growing with storage full is 11b.)
	--==========================================================================
	say("\n-- instant hatch: the pod that was pressed --")
	do
		-- Still growing: it hatches, and nothing else moves (unchanged).
		local g, gPlot, gProfile = w.arrive("PressedGrowing", -629, {
			{ id = "dunebud", tier = 3, wait = 7000 },
			{ id = "petalpip", tier = 2, wait = 6000 },
		}, rowsOf(5))
		local pressed, _, dialogs = w.offer(g, gPlot, 2)
		local other = rowFor(gProfile, "dunebud", 3).HatchAt
		local grew, grewPayload = w.deliver(g, "spec-pressed-1")
		check(pressed == true and dialogs == 1 and grew == GRANTED and grewPayload ~= nil
				and grewPayload.species == "petalpip" and modelFor(gPlot, 2) == nil
				and stillGrowing(gPlot, 1) and rowFor(gProfile, "dunebud", 3).HatchAt == other
				and gProfile.InstantCredits == 0 and #gProfile.Held == 6,
			"the pressed pod, still growing: its receipt hatches it, and only it", tostring(grew))
		local again, againPayload = w.deliver(g, "spec-pressed-1")
		check(again == GRANTED and againPayload == nil and #gProfile.Held == 6 and gProfile.InstantCredits == 0
				and #gProfile.Receipts == 1 and stillGrowing(gPlot, 1),
			"delivered again: already fulfilled, so nothing more: no second hatch and no credit", tostring(again))

		-- Ready while the dialog was open, another pod still growing: a credit.
		local r, rPlot, rProfile = w.arrive("PressedGoesReady", -630, {
			{ id = "toadcap", tier = 2, wait = 3 },
			{ id = "dunebud", tier = 3, wait = 7000 },
		}, rowsOf(5))
		local opened, _, openDialogs = w.offer(r, rPlot, 1)
		local growingBefore = rowFor(rProfile, "dunebud", 3).HatchAt
		task.wait(4.5)
		check(opened == true and openDialogs == 1 and stillReady(rPlot, 1) and stillGrowing(rPlot, 2),
			"(the dialog opened with seconds to go, and the pod's clock ran out while it was open)")
		saveFails[r] = true
		local failing, failingPayload = w.deliver(r, "spec-pressed-2")
		local stillFailing = w.deliver(r, "spec-pressed-2")
		check(failing == RETRY and stillFailing == RETRY and failingPayload == nil and rProfile.InstantCredits == 1
				and #rProfile.Receipts == 1,
			"the save fails: the receipt stays open, and delivered again it adds no second credit",
			tostring(failing) .. " / " .. tostring(stillFailing))
		saveFails[r] = nil
		local kept, keptPayload = w.deliver(r, "spec-pressed-2")
		local save = lastSave(r.Name)
		check(kept == GRANTED and keptPayload == nil and rProfile.InstantCredits == 1
				and save ~= nil and save.worked == true and save.credits == 1 and save.receipts[1] == "spec-pressed-2",
			"answered for once a save holding the credit and its receipt has been written: ONE credit", tostring(kept))
		check(stillReady(rPlot, 1) and stillGrowing(rPlot, 2) and rowFor(rProfile, "dunebud", 3).HatchAt == growingBefore
				and #rProfile.Plants == 2 and #rProfile.Held == 5,
			"the ready pod is not hatched with the purchase, and the purchase is not switched to the pod still growing")
		check(saidTo(r.Name, "INSTANT_CREDIT_READY") == 1, "the buyer is told their pod is ready and the purchase saved")
		local dup = w.deliver(r, "spec-pressed-2")
		check(dup == GRANTED and rProfile.InstantCredits == 1 and #rProfile.Receipts == 1 and stillGrowing(rPlot, 2),
			"delivered again: already fulfilled, no second credit", tostring(dup))

		-- Gone before the receipt: a credit, and no other pod picked.
		local d, dPlot, dProfile = w.arrive("PressedGone", -631, {
			{ id = "spiretip", tier = 1, wait = 3 },
			{ id = "dunebud", tier = 3, wait = 7000 },
		}, rowsOf(5))
		check(w.offer(d, dPlot, 1) == true, "(a dialog opens for a pod with seconds to go)")
		task.wait(4.5)
		local byHand = w.byHand(d, dPlot, 1)
		local goneKept = w.deliver(d, "spec-pressed-3")
		check(byHand == true and modelFor(dPlot, 1) == nil and goneKept == GRANTED and dProfile.InstantCredits == 1
				and stillGrowing(dPlot, 2) and saidTo(d.Name, "INSTANT_CREDIT_SAVED") == 1,
			"the pressed pod hatched by hand while the dialog was open: a credit, and the growing pod is not picked",
			tostring(goneKept))

		-- No note at all, with room and a pod growing: a credit.
		local u, uPlot, uProfile = w.arrive("NoNoteRoom", -632, {
			{ id = "petalpip", tier = 3, wait = 6000 },
		}, rowsOf(5))
		local unnamed = w.deliver(u, "spec-pressed-4")
		check(unnamed == GRANTED and uProfile.InstantCredits == 1 and stillGrowing(uPlot, 1)
				and saidTo(u.Name, "INSTANT_CREDIT_SAVED") == 1 and freePrompt(modelFor(uPlot, 1)),
			"a receipt that names no pod, with room: a credit, and the growing pod's prompt is now free",
			tostring(unnamed))
	end

	--==========================================================================
	-- 11. A PAID HATCH WHOSE SAVE DOES NOT REACH THE DISK
	--==========================================================================
	say("\n-- instant hatch: the save fails --")
	do
		local b, bPlot, bProfile = w.arrive("SaveFails", -609, {
			{ id = "novaorb", tier = 3, wait = 500 },
			{ id = "nubkin", tier = 1, wait = 8000 },
		}, rowsOf(5))
		check(w.PlantService.OfferInstantHatch(b, bPlot, 1) == true, "a purchase dialog opens")
		saveFails[b] = true
		local decision, payload = w.deliver(b, "spec-save-1")
		check(decision == RETRY and payload ~= nil and payload.species == "novaorb"
				and #plantsOf(b) == 6 and #bProfile.Held == 6,
			"the pod hatches, the save fails, and the receipt is not acknowledged",
			tostring(decision))
		local again, againPayload = w.deliver(b, "spec-save-1")
		check(again == RETRY and againPayload == nil and #plantsOf(b) == 6 and #bProfile.Held == 6
				and podsIn(bPlot) == 1,
			"delivered again with the save still failing: not acknowledged, and nothing hatched twice",
			tostring(again))
		saveFails[b] = nil
		local third, thirdPayload = w.deliver(b, "spec-save-1")
		check(third == GRANTED and thirdPayload == nil and #plantsOf(b) == 6 and #bProfile.Held == 6
				and podsIn(bPlot) == 1 and #bProfile.Receipts == 1,
			"acknowledged once the save has been written: one purchase, one plant",
			tostring(third))

		-- A receipt that cannot be recorded is not acknowledged either.
		check(w.PlantService.OfferInstantHatch(b, bPlot, 2) == false,
			"(a second dialog inside the same second is not opened)")
		task.wait(GameConfig.Plant.InstantHatch.OfferGapSeconds + 0.1)
		check(w.PlantService.OfferInstantHatch(b, bPlot, 2) == true, "(a second later it is: the note names pod 2)")
		heldFails[b] = true
		local refused, refusedPayload = w.deliver(b, "spec-save-2")
		heldFails[b] = nil
		task.wait()
		check(refused == RETRY and refusedPayload == nil and #plantsOf(b) == 6 and #bProfile.Held == 6
				and podsIn(bPlot) == 1 and #bProfile.Receipts == 1,
			"a paid hatch whose plant cannot be put on the record: nothing given, nothing acknowledged",
			tostring(refused))
	end

	--==========================================================================
	-- 11b. THE SAME, FOR A PURCHASE THAT MAKES ITS POD READY
	--==========================================================================
	say("\n-- instant hatch: the pod made ready, and a write that fails --")
	do
		local f, fPlot, fProfile = w.arrive("ReadyNotSaved", -616, {
			{ id = "bellchime", tier = 2, wait = 650 },
			{ id = "nubkin", tier = 1, wait = 8000 },
		}, rowsOf(MAX - 1))
		check(w.PlantService.OfferInstantHatch(f, fPlot, 1) == true, "a purchase dialog opens, with room for one")
		w.CarryService.GivePod(f, "spiretip", 1)
		task.wait()
		local before = rowFor(fProfile, "bellchime", 2).HatchAt
		local saidBefore, gardenBefore = saidTo(f.Name), gardenWrites(f.Name)

		-- The garden cannot be written.
		plantsFail[f] = true
		local refused, refusedPayload = w.deliver(f, "spec-ready-1")
		plantsFail[f] = nil
		local model = modelFor(fPlot, 1)
		check(refused == RETRY and refusedPayload == nil and #fProfile.Receipts == 0,
			"a garden that cannot be written: the receipt is not acknowledged", tostring(refused))
		check(stillGrowing(fPlot, 1) and rowFor(fProfile, "bellchime", 2).HatchAt == before
				and model ~= nil and model:GetAttribute("HatchAt") == before
				and gardenWrites(f.Name) == gardenBefore and saidTo(f.Name) == saidBefore,
			"the pod's wait is put back as it was, on the pod and on the record, and nothing is said")
		do
			-- A pod that is not ready answers nothing at all by hand; a ready one
			-- with the record full answers STORAGE_FULL.
			local byHand, byHandWhy = w.byHand(f, fPlot, 1)
			check(byHand == false and byHandWhy == nil and saidTo(f.Name) == saidBefore,
				"and it is not ready: its clock is the one it had",
				tostring(byHand) .. " / " .. tostring(byHandWhy))
		end

		-- The garden is written, and the save does not reach the disk.
		saveFails[f] = true
		local decision, payload = w.deliver(f, "spec-ready-1")
		local deadline = rowFor(fProfile, "bellchime", 2).HatchAt
		check(decision == RETRY and payload == nil and stillReady(fPlot, 1) and deadline <= os.time()
				and gardenWrites(f.Name) == gardenBefore + 1 and saidTo(f.Name, "STORAGE_FULL_READY") == 1
				and saidTo(f.Name) == saidBefore + 1,
			"the pod is made ready and the buyer told, the save fails, and the receipt is not acknowledged",
			tostring(decision))
		local again, againPayload = w.deliver(f, "spec-ready-1")
		check(again == RETRY and againPayload == nil and saidTo(f.Name) == saidBefore + 1
				and gardenWrites(f.Name) == gardenBefore + 1 and stillGrowing(fPlot, 2)
				and rowFor(fProfile, "bellchime", 2).HatchAt == deadline,
			"delivered again with the save still failing: not acknowledged, nothing more made ready or said",
			tostring(again))
		saveFails[f] = nil
		local third, thirdPayload = w.deliver(f, "spec-ready-1")
		local save = lastSave(f.Name)
		check(third == GRANTED and thirdPayload == nil and #fProfile.Receipts == 1
				and save ~= nil and save.worked == true and save.receipts[1] == "spec-ready-1"
				and save.deadlines["bellchime:2"] == deadline and stillGrowing(fPlot, 2)
				and saidTo(f.Name) == saidBefore + 1 and #plantsOf(f) == MAX and #fProfile.Held == MAX,
			"acknowledged once the save has been written, with the purchase and the deadline in it: "
				.. "one purchase, one pod made ready", tostring(third))

		-- The note went with the purchase. Another, with no dialog opened for
		-- it, names no pod (2026-09-30): it is kept as a credit, and neither
		-- comes back to the pod already paid for nor readies the other.
		local second, secondPayload = w.deliver(f, "spec-ready-2")
		check(second == GRANTED and secondPayload == nil and stillGrowing(fPlot, 2) and #fProfile.Receipts == 2
				and saidTo(f.Name, "STORAGE_FULL_READY") == 1 and saidTo(f.Name, "STORAGE_FULL_CREDIT") == 1
				and fProfile.InstantCredits == 1
				and #plantsOf(f) == MAX and #fProfile.Held == MAX,
			"the note of which pod was paid for is spent with the purchase: a second one is a credit, no pod readied",
			tostring(second))
	end

	--==========================================================================
	-- 12. THE SAME RULE WITH THE ROLL SWITCHED OFF, AS IT SHIPS
	--==========================================================================
	say("\n-- with the roll off --")
	do
		local offOk, offErr = pcall(function()
			makeWorld(false)
		end)
		local off = worlds[2]
		check(offOk and off ~= nil and off.HatchRoll.live() == false,
			"a second world loads with the roll switched off", offErr)
		if offOk and off then
			local f, fPlot, fProfile = off.arrive("RollOff", -610, {
				{ id = "nubkin", tier = 1, ready = true },
				{ id = "petalpip", tier = 2, ready = true },
			}, rowsOf(MAX - 1))
			local first, firstWhy, firstPayload = off.byHand(f, fPlot, 1)
			local second, secondWhy, secondPayload = off.byHand(f, fPlot, 2)
			check(first == true and firstWhy == nil and firstPayload ~= nil
					and firstPayload.revealAt == firstPayload.at,
				"the 24th hatches, shown at once")
			check(second == false and secondWhy == "STORAGE_FULL" and secondPayload == nil
					and #plantsOf(f) == MAX and #fProfile.Held == MAX and stillReady(fPlot, 2)
					and saidTo(f.Name, "STORAGE_FULL") == 1,
				"and the 25th is refused, told, and left planted and ready",
				string.format("%s/%s, %d tools, %d rows", tostring(second), tostring(secondWhy),
					#plantsOf(f), #fProfile.Held))

			-- The paid door: nothing about it is the roll's.
			local g, gPlot, gProfile = off.arrive("RollOffPaid", -617, {
				{ id = "nubkin", tier = 2, wait = 800 },
			}, rowsOf(MAX - 1))
			check(off.PlantService.OfferInstantHatch(g, gPlot, 1) == true, "(the dialog opens, with room for one)")
			off.CarryService.GivePod(g, "spiretip", 1)
			task.wait()
			local decision, payload = off.deliver(g, "spec-off-1")
			check(decision == GRANTED and payload == nil and stillReady(gPlot, 1) and #gProfile.Receipts == 1
					and #plantsOf(g) == MAX and #gProfile.Held == MAX
					and saidTo(g.Name, "STORAGE_FULL_READY") == 1,
				"and a purchase that finds no room makes its pod ready, with the roll off as with it on",
				tostring(decision))
		end
	end

	--==========================================================================
	-- 13. A POD GIVEN IS COUNTED TOO (2026-09-30)
	--
	-- GivePod -- the wheel's pod prize, a paid pod -- used to hand a pod over
	-- past the limit without writing it down. The owner's rule: "Ordinary
	-- player actions must respect storage capacity without losing or
	-- duplicating a pod." Its whole story is StorageDoorsSpec's (8b, 8c); here,
	-- that a hatch's record and a given pod's are the same count.
	--==========================================================================
	say("\n-- a pod given is counted too --")
	do
		local m, _, mProfile = w.arrive("PodGiven", -611, {}, rowsOf(MAX))
		local toolsBefore = census(plantsOf(m), toolKey)
		local given = w.CarryService.GivePod(m, "bellchime", 3)
		task.wait()
		check(given == false and #mProfile.Held == MAX and census(plantsOf(m), toolKey) == toolsBefore
				and countKey(plantsOf(m), toolKey, "bellchime:3:false") == 0,
			"at 24 a pod given is refused: no Tool, no row, the record at its limit", tostring(given))
		local room, count = w.CarryService.HeldRoom(m)
		check(room == 0 and count == #mProfile.Held,
			"and the count is still the record's", count)
	end

	--==========================================================================
	-- 14. WHAT THE SCRIPTS SAY
	--==========================================================================
	say("\n-- the source --")
	do
		local carry = sourceOf(Server:FindFirstChild("CarryService")) or ""
		local give = string.match(carry, "function CarryService%.GiveHatched(.-)\nend\n") or ""
		local roomAt = string.find(give, "CarryService.HeldRoom(player)", 1, true)
		local refuseAt = string.find(give, "return false, \"STORAGE_FULL\"", 1, true)
		local buildAt = string.find(give, "CreatureModel.BuildCreature", 1, true)
		local recordAt = string.find(give, "CarryService.RecordHatched(player, species, tier)", 1, true)
		local backAt = string.find(give, "tool:Destroy()", 1, true)
		check(roomAt ~= nil and refuseAt ~= nil and buildAt ~= nil and roomAt < refuseAt and refuseAt < buildAt,
			"GiveHatched counts the room, and refuses, before it builds anything")
		check(recordAt ~= nil and backAt ~= nil and recordAt < backAt
				and string.find(give, "onRecord == true and not CarryService.RecordHatched", 1, true) ~= nil,
			"and takes the Tool back when the row cannot be written")
		local merge = string.match(carry, "local function mergeHeld(.-)\nend\n") or ""
		local savedLoop = string.match(merge, "ipairs%(saved%)(.-)ipairs%(live%)") or "MaxHeld"
		check(merge ~= "" and string.find(savedLoop, "MaxHeld", 1, true) == nil,
			"the merge keeps every row already on the record: the limit is asked only of a new one")
		-- Found in review (2026-09-30): restoreOne is typed to answer one boolean,
		-- and passing GiveHatched's (boolean, reason) straight through broke that.
		local restore = string.match(carry, "local function restoreOne(.-)\nend\n") or ""
		check(restore ~= "" and string.find(restore, "return CarryService.GiveHatched(", 1, true) == nil
				and string.find(restore, "return given", 1, true) ~= nil,
			"a rebuild answers one value: GiveHatched's reason is not passed on as a second answer")

		local plant = sourceOf(Server:FindFirstChild("PlantService")) or ""
		local offer = string.match(plant, "function PlantService%.OfferInstantHatch(.-)\nend\n") or ""
		local askAt = string.find(offer, "CarryService.HeldRoom(player)", 1, true)
		local dialogAt = string.find(offer, "PromptProductPurchase", 1, true)
		local noteAt = string.find(offer, "wanted[player.UserId] =", 1, true)
		check(askAt ~= nil and dialogAt ~= nil and noteAt ~= nil and askAt < noteAt and askAt < dialogAt,
			"OfferInstantHatch counts the room before it writes its note or opens the dialog")
		local paid = string.match(plant, "function PlantService%.InstantHatch(.-)\nend\n") or ""
		local refusedAt = string.find(paid, "if not hatched then", 1, true)
		local falseAt = refusedAt and string.find(paid, "return false", refusedAt, true)
		local clearedAt = string.find(paid, "wanted[player.UserId] = nil", 1, true)
		check(refusedAt ~= nil and falseAt ~= nil and clearedAt ~= nil and falseAt < clearedAt,
			"a refused receipt answers false, and keeps the note of which pod was paid for")
		local endedAt = string.find(paid, "entry.hatchAt = now", 1, true)
		local writtenAt = string.find(paid, "if not persisted(entry.plot) then", 1, true)
		local backAt = string.find(paid, "entry.hatchAt = was", 1, true)
		local trueAt = writtenAt and string.find(paid, "return true", writtenAt, true)
		check(endedAt ~= nil and writtenAt ~= nil and backAt ~= nil and trueAt ~= nil
				and endedAt < writtenAt and writtenAt < backAt and backAt < trueAt,
			"a pod made ready is written to the garden before the receipt is answered for, and put back "
				.. "if it cannot be")
		local keep = string.match(plant, "local function keepForLater(.-)\nend\n") or ""
		local persistentAt = string.find(keep, "PlayerDataService.IsPersistent(player)", 1, true)
		local creditAt = string.find(keep, "PlayerDataService.AddInstantCredits(player, 1)", 1, true)
		check(persistentAt ~= nil and creditAt ~= nil and persistentAt < creditAt
				and string.find(keep, "task.wait", 1, true) == nil,
			"a credit is added only to a profile that can be saved, with nothing that yields before the ledger")
		-- The owner's rule (2026-09-30): a receipt hatches only the pod its note
		-- names -- the same planted pod, still counting down -- and every other
		-- purchase is kept as a credit, before any hatch; no pod is picked in its place.
		local _, keptCalls = string.gsub(paid, "keepForLater%(player,", "")
		local sameAt = string.find(paid, "named == note.entry", 1, true)
		local keepAt = string.find(paid, "if not entry or isReady(entry, now) then", 1, true)
		local keptAt = keepAt and string.find(paid, "keepForLater(player, why)", keepAt, true)
		local hatchCallAt = string.find(paid, "local hatched, why = hatch(player, entry, true)", 1, true)
		local notedAt = string.find(offer, "wanted[player.UserId] = { plot = plot, id = placementId, entry = entry }",
			1, true)
		check(keptCalls == 1 and sameAt ~= nil and keepAt ~= nil and keptAt ~= nil and hatchCallAt ~= nil
				and sameAt < keepAt and keepAt < keptAt and keptAt < hatchCallAt and notedAt ~= nil
				and string.find(paid, "local longest", 1, true) == nil,
			"a receipt hatches only the pod its note names, the same planted pod still counting down, and keeps "
				.. "every other purchase as a credit before any hatch: no pod is picked in its place", keptCalls)
		local hatchedAt = string.find(offer, "local hatched = hatch(player, entry, true)", 1, true)
		local guardAt = hatchedAt and string.find(offer, "if not hatched then", hatchedAt, true)
		local spendAt = string.find(offer, "PlayerDataService.AddInstantCredits(player, -1)", 1, true)
		local sellAt = string.find(offer, "PromptProductPurchase", 1, true)
		check(hatchedAt ~= nil and guardAt ~= nil and spendAt ~= nil and sellAt ~= nil and askAt ~= nil
				and askAt < hatchedAt and hatchedAt < guardAt and guardAt < spendAt and spendAt < sellAt,
			"OfferInstantHatch counts the room, hatches, and takes a credit only after the hatch succeeded -- all "
				.. "before any purchase dialog could open")
	end

	--==========================================================================
	-- 15. THE WORDS
	--
	-- NoticeSpec holds every line to the rules of length and tone, and
	-- HudLayoutSpec measures it on a phone. Here, that each of these says what
	-- happened to the player it is said to.
	--==========================================================================
	say("\n-- the words --")
	do
		local count = string.format("%d/%d", MAX, MAX)
		local full = ActionRefusal.notice("STORAGE_FULL")
		check(full ~= nil and full.kind == "blocked" and full.title == "PLANT STORAGE FULL"
				and string.find(full.detail, count, 1, true) ~= nil
				and string.find(string.lower(full.detail), "room", 1, true) ~= nil
				and ActionRefusal.Text.STORAGE_FULL == string.format("Plant storage full (%s).", count),
			"a refused hatch: PLANT STORAGE FULL, the limit's own number, and what makes room",
			full and (full.title .. " / " .. tostring(full.detail)))
		local made = ActionRefusal.notice("STORAGE_FULL_READY")
		local madeWords = string.lower(made and made.detail or "")
		check(made ~= nil and made.kind == "warning" and made.title == "PLANT STORAGE FULL"
				and string.find(madeWords, "ready", 1, true) ~= nil
				and string.find(madeWords, "free", 1, true) ~= nil
				and string.find(madeWords, "room", 1, true) ~= nil,
			"a purchase that made its pod ready: storage full, the pod is ready, it hatches free with room",
			made and (made.title .. " / " .. tostring(made.detail)))
		local kept = ActionRefusal.notice("STORAGE_FULL_CREDIT")
		local keptWords = string.lower(kept and kept.detail or "")
		check(kept ~= nil and kept.kind == "warning" and kept.title == "PLANT STORAGE FULL"
				and string.find(keptWords, "saved", 1, true) ~= nil and string.find(keptWords, "free", 1, true) ~= nil,
			"a purchase kept as a credit: storage full, the Instant Hatch saved, the next one free",
			kept and (kept.title .. " / " .. tostring(kept.detail)))
		local spent = ActionRefusal.notice("INSTANT_CREDIT_USED")
		check(spent ~= nil and spent.kind == "success"
				and string.find(string.lower(spent.detail or ""), "saved", 1, true) ~= nil,
			"a credit spent: the saved Instant Hatch was used", spent and (spent.title .. " / " .. tostring(spent.detail)))
		check(ActionRefusal.notice("STORAGE_FULL_PAID") == nil and ActionRefusal.Text.STORAGE_FULL_PAID == nil,
			"the old 'Instant Hatch not used' line is gone: a purchase is never left unused now")
		local noPod = ActionRefusal.notice("INSTANT_CREDIT_NO_POD")
		local noPodWords = string.lower(noPod and noPod.detail or "")
		check(noPod ~= nil and noPod.kind == "info" and string.find(noPod.title, "SAVED", 1, true) ~= nil
				and string.find(noPodWords, "free", 1, true) ~= nil and kept ~= nil and noPod.key ~= kept.key,
			"a purchase with nothing to hatch: the Instant Hatch saved, the next one free, a line of its own",
			noPod and (noPod.title .. " / " .. tostring(noPod.detail)))
		local allReady = ActionRefusal.notice("INSTANT_CREDIT_READY")
		local allReadyWords = string.lower(allReady and allReady.detail or "")
		check(allReady ~= nil and allReady.kind == "info" and string.find(allReady.title, "SAVED", 1, true) ~= nil
				and string.find(allReadyWords, "ready", 1, true) ~= nil
				and string.find(allReadyWords, "free", 1, true) ~= nil
				and noPod ~= nil and kept ~= nil and allReady.key ~= noPod.key and allReady.key ~= kept.key,
			"a purchase kept because every pod is ready (option B): saved, the ready pods hatch free, a line of its own",
			allReady and (allReady.title .. " / " .. tostring(allReady.detail)))
		local named = ActionRefusal.notice("INSTANT_CREDIT_SAVED")
		check(named ~= nil and named.kind == "info" and string.find(named.title, "SAVED", 1, true) ~= nil
				and string.find(string.lower(named.detail or ""), "free", 1, true) ~= nil
				and noPod ~= nil and allReady ~= nil and named.key ~= noPod.key and named.key ~= allReady.key,
			"a purchase kept because no pod can be told it was bought for: saved, the next one free, a line of its own",
			named and (named.title .. " / " .. tostring(named.detail)))
		check(full ~= nil and made ~= nil and kept ~= nil and spent ~= nil and full.key ~= made.key
				and made.key ~= kept.key and full.key ~= kept.key and kept.key ~= spent.key,
			"each is a line of its own on the screen: one does not stand in for another")
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
fixture:Destroy()
for name, fn in pairs(real) do
	PlayerDataService[name] = fn
end

say(string.format("\nHatchStorageSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
