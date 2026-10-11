--!nocheck
--==============================================================================
-- Steal a Seed :: HatchDeliverySpec
--
-- WHAT A HATCH MUST NEVER COST (2026-09-29). Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HatchDeliverySpec"))
--
-- The owner's rules:
--
--   "The server must determine and secure the real outcome independently of
--    the animation -- this is a visual reveal, not a second roll."
--   "A disconnect, death, closed panel, or client error during the animation
--    must never lose or duplicate the plant."
--
-- So two things are asserted, for a hatch whose roll is still running:
--
--   OUTCOME IDENTITY   the pod that was planted, the Tool that is handed over,
--                      the row that is saved and the message that starts the
--                      animation are one plant: one species, one size.
--   EXACTLY ONCE       one hatch is one Tool and one row, whatever happens
--                      next: a second receipt, a stranger, no Backpack at that
--                      instant, a death before or during the roll, leaving,
--                      coming back.
--
-- THE REAL PlantService AND THE REAL CarryService, the roll switched ON, each
-- loaded from its source. What stands in is what a spec cannot have:
-- PlotService (a plot with an owner), the profile store (IsReady / Get /
-- SetHeld / SetPlants / MarkSeen, replaced on the PlayerDataService both of
-- them call), the Players service (so that a player leaving can be played),
-- and the players -- tables whose signals are real and whose Backpack and body
-- are real instances, destroyed the way the engine destroys them
-- (HeldRestoreSpec's).
--
-- The paid door is the one driven, as in HatchRevealSpec: a receipt is a
-- function call, and a held prompt is the engine's. Both run the same hatch().
--
-- Not here: what any of it looks like -- nothing in this file is a client.
-- HatchRollSpec has the roll's arithmetic, the masks, and the world's side.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PlayerDataService = require(Server:WaitForChild("PlayerDataService"))
local PlantWander = require(Server:WaitForChild("PlantWander"))
local MapService = require(Server:WaitForChild("MapService"))

local HATCH = GameConfig.Plant.Hatch
local ROLL = HATCH.Roll
local KG = GameConfig.Attributes.CarryingKg
local MAX_HELD = GameConfig.Save.MaxHeld

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

local function near(a, b)
	return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 1e-6
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

local rollConfig = setmetatable({ Enabled = true, StudioPreview = false }, { __index = ROLL })
local hatchConfig = setmetatable({ Roll = rollConfig }, { __index = HATCH })
-- No gap between purchase dialogs, so a press can come straight before each receipt.
local instantConfig = setmetatable({ OfferGapSeconds = 0 }, { __index = GameConfig.Plant.InstantHatch })
local plantConfig = setmetatable({ Hatch = hatchConfig, InstantHatch = instantConfig },
	{ __index = GameConfig.Plant })
local SPEC_PRODUCT = 990011
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
-- THE PLAYERS (HeldRestoreSpec's), AND THE SERVICE THEY ARE IN
--==============================================================================
-- What each service does when somebody leaves, to be called when somebody does.
local leaving = {}
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
local fixture = Instance.new("Folder")
fixture.Name = "HatchDeliverySpecFixture"
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

-- Every plant Tool this player has, in the bag and in the hands.
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
}
local ready = {}
local profiles = {}
-- Every write, in order: who, which list, how many rows -- and for a garden
-- write, how many rows the record held at that moment.
local writes = {}

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
PlayerDataService.RecordTutorial = function() end

local function smallestHeld(name, since)
	local smallest = math.huge
	for i, w in ipairs(writes) do
		if w.who == name and w.list == "Held" and i > (since or 0) then
			smallest = math.min(smallest, w.rows)
		end
	end
	return smallest
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
	plot.Name = "HatchDeliverySpecPlot" .. index
	plot.Archivable = false
	plot:SetAttribute("PreviewOnly", true)
	plot:SetAttribute(GameConfig.Attributes.PlotId, 100 + index)
	plot.Parent = Workspace
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	local y = 1000 + index * 60
	plot:SetAttribute("PlotCF", CFrame.lookAt(Vector3.new(0, y, centreR), Vector3.new(0, y, 0)))
	plot:SetAttribute("Depth", startDepth)
	MapService.ResizePlot(plot, 1)
	table.insert(plots, plot)
	return plot
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

-- A garden of pods that a receipt hatches in the order given: with no note
-- against it, a receipt takes the pod with the longest wait left.
local function gardenOf(pods)
	local rows = {}
	local stamp = os.time()
	for i, pod in ipairs(pods) do
		table.insert(rows, { SpeciesId = pod.id, Tier = pod.tier, PlantedAt = stamp,
			HatchAt = stamp + 9000 - i * 100, X = -12 + i * 3, Z = -4, Stage = 1, Facing = 0 })
	end
	return rows
end

local PlantService = nil
local HatchRoll = nil
local reveals = {}

-- Here, armed, with a garden. Returns the player, their plot and their profile.
local function arrive(name, userId, pods, held, profile)
	local p = living(name, userId)
	profile = profile or { Plants = gardenOf(pods), Held = held or {}, Almanac = {} }
	profiles[p] = profile
	ready[p] = true
	newBackpack(p, false)
	newBody(p, false)
	CarryService.WatchHeld(p)
	CarryService.RestoreHeld(p)
	task.wait(0.4)
	local plot = newPlot()
	plotOf[p] = plot
	ownerOf[plot] = p
	assignedFn(p, plot)
	return p, plot, profile
end

-- A receipt hatches the pod that was pressed and no other (the owner, 2026-09-30):
-- one with no note keeps a credit. So each receipt here is preceded by its press,
-- on the pod a player would press next -- of those still counting down, the one
-- with the longest wait, ties to the lower id -- and the spec's config has no gap
-- between dialogs, so presses can follow each other as fast as the receipts do.
local function pressNext(p, plot)
	local best, bestAt = nil, -math.huge
	for _, d in ipairs(plot:GetDescendants()) do
		-- Planted: a hatched pod stays in the plot for its reveal, untagged.
		if d:IsA("Model") and d:GetAttribute("PlacementId") ~= nil and d:GetAttribute("Stage") == 1
			and game:GetService("CollectionService"):HasTag(d, GameConfig.Tags.Planted)
			and d:GetAttribute("Ready") ~= true then
			local at = tonumber(d:GetAttribute("HatchAt")) or 0
			local id = d:GetAttribute("PlacementId")
			if at > bestAt or (at == bestAt and best ~= nil and id < best) then
				best, bestAt = id, at
			end
		end
	end
	if best ~= nil then
		PlantService.OfferInstantHatch(p, plot, best)
	end
	return best
end

-- One receipt, after its press. Answers what InstantHatch said, the
-- announcement it made (or nil), and whether it ran from start to finish
-- without yielding.
local function receipt(p)
	local plot = plotOf[p]
	if plot then
		pressNext(p, plot)
	end
	local before = #reveals
	local answered, done = nil, false
	local thread = coroutine.create(function()
		answered = PlantService.InstantHatch(p)
		done = true
	end)
	local resumed = coroutine.resume(thread)
	return answered, reveals[before + 1], resumed and done
end

-- A teardown step, followed by the stray syncs that land in a real one.
local function step(p, fn)
	fn()
	CarryService.SyncHeldNow(p)
	task.wait(0.05)
	CarryService.SyncHeldNow(p)
end

-- A death, in the engine's order. Returns the new Backpack and body.
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
	local newBodyModel = newBody(p, false)
	step(p, function()
		p._fire.characterAdded:Fire(newBodyModel)
	end)
	task.wait(0.6)
	return newPack, newBodyModel
end

local function body()
	HatchRoll = loadWith(Shared.HatchRoll, { GameConfig = liveConfig, SeedData = SeedData })

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
			-- The Mysterious Pod (2026-10-11): no shells in this fixture.
			MysteryPodService = { IsShell = function() return false end, Outcome = function() return nil end,
				Consume = function() end, TellHatch = function() end },
		}, { GameConfig = liveConfig, HatchRoll = HatchRoll }, fakeGame)
		PlantService.Init()
		PlantService.Start()
	end)
	check(loadOk and assignedFn ~= nil and HatchRoll.live() == true,
		"the real PlantService loads over the real CarryService, with the roll switched on", loadErr)
	if not (loadOk and assignedFn) then
		return
	end
	PlantService.OnRevealed(function(payload)
		table.insert(reveals, payload)
	end)
	local seconds = HatchRoll.seconds()

	--==========================================================================
	-- 1. ONE PLANT: THE POD, THE TOOL, THE ROW AND THE MESSAGE
	--==========================================================================
	say("\n-- outcome identity: every rarity, every size --")
	do
		-- One species of each rarity the game has plants of, and every size.
		local byRarity, rarities = {}, {}
		for _, species in ipairs(SeedData.Species) do
			if byRarity[species.Rarity] == nil then
				byRarity[species.Rarity] = species
				table.insert(rarities, species.Rarity)
			end
		end
		table.sort(rarities, function(a, b)
			return (GameConfig.RarityTier[a] or 0) < (GameConfig.RarityTier[b] or 0)
		end)
		local sizes = { 1, 4, 7, 2, 6, 3, 5 }
		local pods = {}
		for i, rarity in ipairs(rarities) do
			table.insert(pods, { id = byRarity[rarity].Id, tier = sizes[(i - 1) % #sizes + 1] })
		end
		local covered = {}
		for _, pod in ipairs(pods) do
			covered[pod.tier] = true
		end
		for _, tier in ipairs(sizes) do
			if not covered[tier] then
				table.insert(pods, { id = byRarity[rarities[1]].Id, tier = tier })
				covered[tier] = true
			end
		end
		check(#rarities >= 5 and #pods >= SeedData.TierCount,
			string.format("%d pods: one of each of %d rarities, and all %d sizes", #pods, #rarities,
				SeedData.TierCount), table.concat(rarities, ","))

		local p, plot, profile = arrive("Identity", -401, pods)
		check(CarryService.IsHeldRestored(p) and podsIn(plot) == #pods and #profile.Plants == #pods,
			"they are here, their record is open, and the pods are in the ground", podsIn(plot))

		local same = { hatched = 0, whole = 0, message = 0, tool = 0, secret = 0, row = 0, garden = 0,
			order = 0, frames = 0, once = 0 }
		local firstWrong = nil
		for i, pod in ipairs(pods) do
			local species = SeedData.Get(pod.id)
			local toolsBefore = {}
			for _, tool in ipairs(plantsOf(p)) do
				toolsBefore[tool] = true
			end
			local mark = #writes
			local answered, payload, whole = receipt(p)
			local made = {}
			for _, tool in ipairs(plantsOf(p)) do
				if not toolsBefore[tool] then
					table.insert(made, tool)
				end
			end
			local tool = made[1]
			local ok = {}
			ok.hatched = answered == true and payload ~= nil
			ok.whole = whole == true
			ok.once = #made == 1
			ok.message = payload ~= nil and payload.species == pod.id and payload.tier == pod.tier
				and payload.rarity == species.Rarity and payload.owner == p
				and near(payload.income, SeedData.IncomePerSecond(species, pod.tier))
			ok.tool = tool ~= nil and tool:GetAttribute("SpeciesId") == pod.id
				and tool:GetAttribute(KG) == pod.tier and tool:GetAttribute("Hatched") == true
				and tool.Name == species.Name
			ok.secret = tool ~= nil and payload ~= nil
				and tool:GetAttribute(ROLL.Attribute) == payload.revealAt
				and near(payload.revealAt - payload.at, seconds) and HatchRoll.sealed(tool)
			-- The record: one row more, and the same plants as the Tools.
			ok.row = #profile.Held == i
				and census(profile.Held, rowKey) == census(plantsOf(p), toolKey)
			-- The garden: that pod, and only that pod, is out of it.
			local left = {}
			for j = i + 1, #pods do
				table.insert(left, { Id = pods[j].id, Tier = pods[j].tier, Hatched = false })
			end
			local inGarden = {}
			for _, row in ipairs(profile.Plants) do
				table.insert(inGarden, { Id = row.SpeciesId, Tier = row.Tier, Hatched = false })
			end
			ok.garden = #profile.Plants == #pods - i and census(inGarden, rowKey) == census(left, rowKey)
			-- The order: when the garden was saved without the pod, the record
			-- already held the plant.
			local saved = nil
			for j = mark + 1, #writes do
				if writes[j].who == p.Name and writes[j].list == "Plants" then
					saved = writes[j]
				end
			end
			ok.order = saved ~= nil and saved.heldThen == i and saved.toolsThen == i
			local frames = payload and HatchRoll.frames(payload.species, payload.token)
			ok.frames = frames ~= nil and tool ~= nil
				and frames[#frames].speciesId == tool:GetAttribute("SpeciesId")
			for name, good in pairs(ok) do
				if good then
					same[name] += 1
				elseif firstWrong == nil then
					firstWrong = string.format("%s, pod %d (%s T%d)", name, i, pod.id, pod.tier)
				end
			end
		end
		local n = #pods
		check(same.hatched == n, string.format("all %d hatch", n), firstWrong)
		check(same.whole == n, "each from its guards to its announcement without one yield", same.whole)
		check(same.once == n, "each makes exactly one Tool", same.once)
		check(same.message == n,
			"the message names the pod's own species, size, rarity and income, and its owner",
			firstWrong)
		check(same.tool == n, "the Tool is that species at that size, hatched, under its own name",
			firstWrong)
		check(same.row == n,
			"the record grows by one row each time, and lists exactly the plants the Tools are",
			firstWrong)
		check(same.garden == n, "the garden loses that pod and no other", firstWrong)
		check(same.order == n,
			"and when the garden is saved without the pod, the plant is already on the record",
			firstWrong)
		check(same.secret == n,
			"the Tool is a secret until the very time the message gives, three seconds on",
			firstWrong)
		check(same.frames == n, "and the silhouettes that message draws end on the Tool's own plant",
			firstWrong)
		local tokens, distinct = {}, 0
		for _, payload in ipairs(reveals) do
			if not tokens[payload.token] then
				tokens[payload.token] = true
				distinct += 1
			end
		end
		check(distinct == #reveals and #reveals == n, "one announcement for each, each with its own token",
			string.format("%d announcements, %d tokens", #reveals, distinct))
		local keys = {}
		for _, row in ipairs(profile.Held) do
			for key in pairs(row) do
				keys[key] = true
			end
		end
		local named = {}
		for key in pairs(keys) do
			table.insert(named, key)
		end
		table.sort(named)
		check(table.concat(named, ",") == "Hatched,Id,Tier",
			"a saved row is a species, a size and a flag: the roll's time is never saved",
			table.concat(named, ","))

		--== AND NOT ONE MORE ==--
		say("\n-- exactly once --")
		local tools, rows, told = #plantsOf(p), #profile.Held, #reveals
		local again, none = receipt(p)
		check(again == false and none == nil,
			"a receipt with no pod left to hatch is refused, so Roblox keeps it and nothing is charged for")
		check(PlantService.OfferInstantHatch(p, plot, 1) == false,
			"the pod that hatched cannot be offered again")
		check(#plantsOf(p) == tools and #profile.Held == rows and #reveals == told
				and #profile.Plants == 0 and podsIn(plot) == 0,
			"and nothing was handed over, recorded or announced a second time",
			string.format("%d tools, %d rows", #plantsOf(p), #profile.Held))
	end

	--==========================================================================
	-- 2. NOBODY ELSE, AND NOT WITHOUT SOMEWHERE TO PUT IT
	--==========================================================================
	say("\n-- the ones that do not hatch --")
	do
		local p, plot, profile = arrive("NoBackpack", -402,
			{ { id = "nubkin", tier = 2 }, { id = "novaorb", tier = 4 } })
		local stranger = living("Stranger", -403)
		profiles[stranger] = { Plants = {}, Held = {}, Almanac = {} }
		ready[stranger] = true
		newBackpack(stranger, false)
		newBody(stranger, false)
		local told, mark = #reveals, #writes
		check(PlantService.OfferInstantHatch(stranger, plot, 1) == false
				and PlantService.InstantHatch(stranger) == false,
			"a stranger can neither be offered somebody's pod nor hatch one with a receipt")
		check(#plantsOf(stranger) == 0 and #plantsOf(p) == 0 and #reveals == told and #writes == mark,
			"and nobody is handed, or saved, anything")

		-- Dying with the prompt held: no Backpack at that instant.
		local pack = p._backpack
		p._backpack = nil
		local answered, payload = receipt(p)
		check(answered == false and payload == nil, "a hatch with nowhere to put the plant does not happen")
		check(#profile.Plants == 2 and podsIn(plot) == 2 and #profile.Held == 0 and #writes == mark,
			"the pod is still in the ground and still in the save: nothing was taken for nothing")
		p._backpack = pack
		local after, second = receipt(p)
		check(after == true and second ~= nil and second.species == "nubkin" and second.tier == 2
				and near(second.revealAt, second.at + seconds),
			"and it hatches when it can be, with three seconds of its own")
		check(#plantsOf(p) == 1 and #profile.Held == 1 and #profile.Plants == 1,
			"one Tool, one row, one pod fewer")
	end

	--==========================================================================
	-- 3. A DEATH DURING THE ROLL
	--==========================================================================
	say("\n-- a death during the roll --")
	do
		local p, _, profile = arrive("DiesRolling", -404,
			{ { id = "dunebud", tier = 7 }, { id = "petalpip", tier = 1 } },
			{ { Id = "nubkin", Tier = 3, Hatched = true } })
		check(#plantsOf(p) == 1 and #profile.Held == 1, "they arrive holding a plant from before")
		local _, first = receipt(p)
		local _, second = receipt(p)
		check(first ~= nil and second ~= nil and near(first.revealAt, first.at + seconds)
				and near(second.revealAt, second.at + seconds) and second.revealAt - first.revealAt < 0.5,
			"two pods hatched together are two rolls side by side, each three seconds from its own hatch")
		check(#plantsOf(p) == 3 and #profile.Held == 3 and #profile.Plants == 0,
			"three Tools, three rows, and an empty garden")

		local mark = #writes
		die(p)
		local tools = plantsOf(p)
		check(#tools == 3 and census(tools, toolKey) == "dunebud:7:true x1, nubkin:3:true x1, petalpip:1:true x1",
			"after the death every plant is back, each once", census(tools, toolKey))
		check(#profile.Held == 3 and smallestHeld(p.Name, mark) >= 3,
			"the record lists three, and no write through the whole death carried fewer",
			smallestHeld(p.Name, mark))
		local stillSecret, oldShown = 0, false
		for _, tool in ipairs(tools) do
			local id = tool:GetAttribute("SpeciesId")
			local at = tool:GetAttribute(ROLL.Attribute)
			if id == "dunebud" and at == first.revealAt and HatchRoll.sealed(tool) then
				stillSecret += 1
			elseif id == "petalpip" and at == second.revealAt and HatchRoll.sealed(tool) then
				stillSecret += 1
			elseif id == "nubkin" and at == nil then
				oldShown = true
			end
		end
		check(stillSecret == 2,
			"the two whose rolls are running come back as the secrets they were, until their own times",
			stillSecret)
		check(oldShown, "and the plant from before comes back as itself")

		-- The rolls end: the server takes the time off both Tools.
		local wait = math.max(first.revealAt, second.revealAt) - Workspace:GetServerTimeNow()
		if wait > 0 then
			task.wait(wait + 0.25)
		end
		local shown = 0
		for _, tool in ipairs(plantsOf(p)) do
			if tool:GetAttribute(ROLL.Attribute) == nil and not HatchRoll.sealed(tool) then
				shown += 1
			end
		end
		check(shown == 3, "when their times come the server takes the time off the Tools it rebuilt", shown)
		die(p)
		local shownAfter = 0
		for _, tool in ipairs(plantsOf(p)) do
			if tool:GetAttribute(ROLL.Attribute) == nil then
				shownAfter += 1
			end
		end
		check(#plantsOf(p) == 3 and shownAfter == 3,
			"and a death after a roll is over brings its plant back shown: a secret does not come back")

		-- Two deaths inside one secret, and a secret that runs out during a death.
		local q, _, qProfile = arrive("DiesTwice", -410, {})
		local began = Workspace:GetServerTimeNow()
		CarryService.GiveHatched(q, SeedData.Get("novaorb"), 4, 8, began + 8, true)
		CarryService.GiveHatched(q, SeedData.Get("raincup"), 2, 0.5, began + 0.5, true)
		check(#plantsOf(q) == 2 and #qProfile.Held == 2, "two plants are given, each with a time of its own")
		local function secrets()
			local long, short = false, false
			for _, tool in ipairs(plantsOf(q)) do
				local id = tool:GetAttribute("SpeciesId")
				if id == "novaorb" then
					long = tool:GetAttribute(ROLL.Attribute) == began + 8 and HatchRoll.sealed(tool)
				elseif id == "raincup" then
					short = tool:GetAttribute(ROLL.Attribute) ~= nil
				end
			end
			return long, short
		end
		die(q)
		local long, short = secrets()
		check(#plantsOf(q) == 2 and #qProfile.Held == 2 and long and not short,
			"after a death the one still running is still a secret, and the one that ran out is shown")
		die(q)
		long, short = secrets()
		check(#plantsOf(q) == 2 and #qProfile.Held == 2 and long and not short,
			"and after a second death in the same roll, the same: still two plants, still one secret")
	end

	--==========================================================================
	-- 4. A HATCH THAT LANDS WHILE THE BODY IS BEING REPLACED
	--==========================================================================
	say("\n-- a receipt in the middle of a respawn --")
	do
		local p, _, profile = arrive("HatchedMidRespawn", -405, { { id = "novaorb", tier = 5 } },
			{ { Id = "nubkin", Tier = 1, Hatched = true }, { Id = "nubkin", Tier = 1, Hatched = true } })
		local pack, bodyModel = p._backpack, p.Character
		-- The old body is going: recording is off from here.
		p._fire.characterRemoving:Fire(bodyModel)
		task.wait(0.05)
		check(not CarryService.IsHeldRestored(p), "the body is on its way out and the record is closed to snapshots")
		local answered, payload = receipt(p)
		check(answered == true and payload ~= nil and payload.species == "novaorb",
			"the receipt is honoured: the pod hatches into the Backpack that is still there")
		check(#profile.Held == 3 and census(profile.Held, rowKey) == "novaorb:5:true x1, nubkin:1:true x2",
			"and the plant is on the record at once, though no snapshot may be taken",
			census(profile.Held, rowKey))
		-- The rest of the death: the Backpack goes, and the new Tool with it.
		step(p, function()
			p.Character = nil
			bodyModel:Destroy()
		end)
		step(p, function()
			pack:Destroy()
		end)
		local newPack = newBackpack(p, false)
		step(p, function()
			p._fire.childAdded:Fire(newPack)
		end)
		local newBodyModel = newBody(p, false)
		step(p, function()
			p._fire.characterAdded:Fire(newBodyModel)
		end)
		task.wait(0.6)
		local tools = plantsOf(p)
		check(#tools == 3 and census(tools, toolKey) == "novaorb:5:true x1, nubkin:1:true x2",
			"the respawn rebuilds it with the rest: the plant that hatched mid-respawn, once",
			census(tools, toolKey))
		check(#profile.Held == 3 and #profile.Plants == 0, "three rows, no pod: nothing lost, nothing twice")

		-- The same, but the new Backpack is already there when the receipt lands.
		local q, _, qProfile = arrive("HatchedIntoNewPack", -406, { { id = "petalpip", tier = 2 } },
			{ { Id = "nubkin", Tier = 1, Hatched = true } })
		local oldPack, oldBody = q._backpack, q.Character
		q._fire.characterRemoving:Fire(oldBody)
		q.Character = nil
		oldBody:Destroy()
		oldPack:Destroy()
		local freshPack = newBackpack(q, false)
		local qAnswered = receipt(q)
		check(qAnswered == true and #qProfile.Held == 2,
			"a receipt that lands in the new, not yet rebuilt Backpack is recorded too")
		q._fire.childAdded:Fire(freshPack)
		local freshBody = newBody(q, false)
		q._fire.characterAdded:Fire(freshBody)
		task.wait(0.8)
		local qTools = plantsOf(q)
		check(#qTools == 2 and census(qTools, toolKey) == "nubkin:1:true x1, petalpip:2:true x1"
				and #qProfile.Held == 2,
			"and the rebuild counts the Tool that is already there: two plants, not three",
			census(qTools, toolKey))
	end

	--==========================================================================
	-- 5. LEAVING DURING THE ROLL, AND COMING BACK
	--==========================================================================
	say("\n-- leaving during the roll --")
	do
		local p, _, profile = arrive("LeavesRolling", -407,
			{ { id = "dunebud", tier = 6 }, { id = "nubkin", tier = 2 } })
		local _, payload = receipt(p)
		check(payload ~= nil and #plantsOf(p) == 1 and HatchRoll.sealed(plantsOf(p)[1]),
			"a pod hatches and its roll is running")
		local mark = #writes
		-- Gone: the session is pulled down around the Tools.
		local pack, bodyModel = p._backpack, p.Character
		check(#leaving >= 1, "the services are listening for a player leaving", #leaving)
		for _, fn in ipairs(leaving) do
			fn(p)
		end
		p.Parent = nil
		step(p, function()
			p._fire.characterRemoving:Fire(bodyModel)
		end)
		step(p, function()
			p.Character = nil
			bodyModel:Destroy()
		end)
		step(p, function()
			pack:Destroy()
		end)
		task.wait(0.3)
		check(#profile.Held == 1 and rowKey(profile.Held[1]) == "dunebud:6:true"
				and smallestHeld(p.Name, mark) >= 1,
			"the save they leave with has the plant: nothing the teardown wrote took it off",
			census(profile.Held, rowKey))
		check(#profile.Plants == 1 and profile.Plants[1].SpeciesId == "nubkin",
			"and not the pod it came out of: the other pod only")

		-- Back, on a new server for all the record knows.
		ready[p] = nil
		local back, plot = arrive("LeavesRolling", -407, nil, nil, profile)
		local tools = plantsOf(back)
		check(#tools == 1 and toolKey(tools[1]) == "dunebud:6:true",
			"they come back to that plant, once", census(tools, toolKey))
		check(tools[1] ~= nil and tools[1]:GetAttribute(ROLL.Attribute) == nil
				and not HatchRoll.sealed(tools[1]),
			"shown: a roll is not resumed for somebody who was not there for it")
		check(podsIn(plot) == 1 and #profile.Plants == 1,
			"and to a garden with one pod in it, not two")
		local answered, next = receipt(back)
		check(answered == true and next ~= nil and next.species == "nubkin"
				and near(next.revealAt, next.at + seconds),
			"the next hatch is the other pod, with three seconds of its own")
		local none = receipt(back)
		check(none == false and #plantsOf(back) == 2 and #profile.Held == 2 and #profile.Plants == 0,
			"and then there is nothing left to hatch: two plants, two rows, an empty garden",
			string.format("%d tools, %d rows, %d pods", #plantsOf(back), #profile.Held, #profile.Plants))
	end

	--==========================================================================
	-- 6. THE TIME ON THE TOOL IS A CLAIM
	--==========================================================================
	say("\n-- what CarryService does with a time --")
	do
		local p, _, profile = arrive("Times", -408, {})
		local species = SeedData.Get("nubkin")
		local now = Workspace:GetServerTimeNow()
		local function give(tier, equipAfter, revealAt, onRecord)
			local before = {}
			for _, tool in ipairs(plantsOf(p)) do
				before[tool] = true
			end
			local ok = CarryService.GiveHatched(p, species, tier, equipAfter, revealAt, onRecord)
			for _, tool in ipairs(plantsOf(p)) do
				if not before[tool] then
					return ok, tool
				end
			end
			return ok, nil
		end
		local _, plain = give(1, nil, nil, nil)
		check(plain ~= nil and plain:GetAttribute(ROLL.Attribute) == nil,
			"a plant given with no time -- a pickup, a rejoin -- has none on it")
		local _, past = give(2, nil, now - 3, nil)
		local _, never = give(3, nil, now + ROLL.MaxHideSeconds + 60, nil)
		local _, notNumber = give(4, nil, 0 / 0, nil)
		check(past ~= nil and past:GetAttribute(ROLL.Attribute) == nil
				and never ~= nil and never:GetAttribute(ROLL.Attribute) == nil
				and notNumber ~= nil and notNumber:GetAttribute(ROLL.Attribute) == nil,
			"a time already past, further off than any roll, or not a number is no secret at all")
		local _, brief = give(5, 0.4, now + 0.4, nil)
		check(brief ~= nil and brief:GetAttribute(ROLL.Attribute) == now + 0.4 and HatchRoll.sealed(brief),
			"a time just ahead is written on the Tool")
		task.wait(0.2)
		check(#profile.Held == 5, "every one of them is on the record", #profile.Held)
		task.wait(0.5)
		check(brief ~= nil and brief.Parent ~= nil and brief:GetAttribute(ROLL.Attribute) == nil
				and not HatchRoll.sealed(brief),
			"and taken off by the server when it comes, with nobody asking")
	end

	--==========================================================================
	-- 7. THE ONE LIMIT (2026-09-29: the owner has decided; this was a note)
	--
	-- Measured here first: with 24 plants saved, a hatch answered true, made a
	-- Tool, and wrote no row -- a plant on nobody's record. The owner's
	-- decision: "refuse the hatch and leave the pod planted and ready until the
	-- player makes room". HatchStorageSpec has every side of that; here, that a
	-- hatch whose roll would run is refused like any other, and leaves no
	-- secret behind.
	--
	-- The hatch here is a paid one, and a purchase that finds no room "should
	-- make its intended pod ready immediately" (the owner, the same day): so the
	-- receipt is answered for, and what it is answered for is a pod made ready
	-- -- not a plant, not an announcement, and not a roll.
	--==========================================================================
	say("\n-- the saved bag's limit --")
	do
		local full = {}
		for _ = 1, MAX_HELD - 1 do
			table.insert(full, { Id = "nubkin", Tier = 1, Hatched = true })
		end
		local p, plot, profile = arrive("FullRecord", -409, { { id = "novaorb", tier = 4 } }, full)
		task.wait(0.4)
		-- Pressed with room for one (a full record opens no dialog), and the record
		-- filled while the dialog was open: a receipt for the pod that was pressed.
		pressNext(p, plot)
		-- The 24th PLANT (a pod would not fill it: since 2026-10-09 pods have a
		-- room of their own).
		CarryService.GiveHatched(p, SeedData.Get("spiretip"), 1, -1, nil, true)
		task.wait()
		local answered, payload, ranThrough = receipt(p)
		local onRecord = false
		for _, row in ipairs(profile.Held) do
			if row.Id == "novaorb" then
				onRecord = true
			end
		end
		check(answered == true and payload == nil and ranThrough,
			"with 24 plants already saved, a paid hatch is refused: nothing hatches and nothing is announced",
			tostring(answered))
		check(#plantsOf(p) == MAX_HELD and #profile.Held == MAX_HELD and not onRecord,
			"no Tool is made and no row is written: nothing is held that is not on the record",
			string.format("%d tools, %d rows", #plantsOf(p), #profile.Held))
		check(podsIn(plot) == 1 and #profile.Plants == 1 and profile.Plants[1].SpeciesId == "novaorb"
				and profile.Plants[1].Stage == 1 and profile.Plants[1].HatchAt <= os.time(),
			"the pod is still in the garden, and what the purchase did is end its wait",
			string.format("%d pods, deadline %s", podsIn(plot), tostring(profile.Plants[1].HatchAt)))
		local sealed = 0
		for _, tool in ipairs(plantsOf(p)) do
			if tool:GetAttribute(ROLL.Attribute) ~= nil then
				sealed += 1
			end
		end
		check(sealed == 0, "no plant is left called ???: a refused hatch starts no roll", sealed)
		check(#profile.Held <= MAX_HELD, "the record never goes past its limit", #profile.Held)
	end
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

if PlantService then
	pcall(PlantService.Init)
end
if CarryService then
	pcall(CarryService.Init)
end
for name, fn in pairs(real) do
	PlayerDataService[name] = fn
end
for _, plot in ipairs(plots) do
	plot:Destroy()
end
fixture:Destroy()

say(string.format("\nHatchDeliverySpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
