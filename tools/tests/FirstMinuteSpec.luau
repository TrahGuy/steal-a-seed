--!nocheck
--==============================================================================
-- Steal a Seed :: FirstMinuteSpec
-- THE FIRST MINUTE (the owner's brief, 2026-10-08). Edit mode:
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("FirstMinuteSpec"))
--
-- The owner's checks:
--   the starter   given once to a fresh profile; never to an existing one;
--                 never twice; hatches itself at 30 s; records no milestone;
--                 not counted by Sanitise, HasOutstandingPod or the Bonus
--                 Chest; the reserved pod is still offered
--   the target    400, and old saves at or above 400 are credited
--   the raid      a player at 400 carrying a pod gets home with the margin;
--                 Speed 0 is caught; a second theft and other players are
--                 unchanged
--   the catch     the first pod is Big or bigger, once
--   untouched     the grow ladder and income
-- and the saves: the new fields default safely on every old save, and a v3
-- tutorial record with a full garden loads exactly as it did.
--
-- THE REAL PlantService, loaded from its Source with the roll switched off,
-- restored into real Level 1 plots dressed by MapService far above the map.
-- PlotService, PlayerDataService, CarryService, Players, MarketplaceService
-- and the GameEvent remote stand in and RECORD what they are asked: no save is
-- read or written and nothing reaches a client. THE REAL NestService's provoke
-- on nest records built here (SpecProvoke, SpecStealDone, SpecChaseSpeed), in
-- the "returning" state so no wake roar sounds in Studio -- the first raid is
-- decided by the rage, not the state. THE REAL BonusChestService.Claim, as
-- TutorialSpec loads it. Everything else is the shipped pure modules.
--
-- Simulated user ids from 90,000,000,000; no real player is named.
-- Not here: what any of it looks like, and the times (the guarded Play).
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local Data = require(Shared:WaitForChild("TutorialData"))
local FirstMinute = require(Shared:WaitForChild("FirstMinute"))
local Spot = require(Shared:WaitForChild("TutorialSpotlight"))
local Notice = require(Shared:WaitForChild("Notice"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Schema = require(Server:WaitForChild("ProfileSchema"))
local PlantWander = require(Server:WaitForChild("PlantWander"))
local MapService = require(Server:WaitForChild("MapService"))
local NestService = require(Server:WaitForChild("NestService"))

local P = GameConfig.Parent
local HATCH = GameConfig.Plant.Hatch

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

local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return (found :: any).Source
	end)
	return if ok and type(src) == "string" then src else ""
end

local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end

local function occurrences(src, needle)
	local n, at = 0, 1
	while true do
		local s, e = string.find(src, needle, at, true)
		if not s then
			return n
		end
		n += 1
		at = e + 1
	end
end

local green = BiomeData.ById.greenhollow
local dustbowl = BiomeData.ById.dustbowl
local starterSpecies = SeedData.Get(FirstMinute.StarterSpecies)

--==============================================================================
-- 1. THE TARGET IS 400, AND EVERY WORD ABOUT IT SAYS SO
--==============================================================================
say("-- the target --")
do
	check(Data.SpeedTarget == 400 and Data.SpeedTargetText == "400", "Tutorial.SpeedTarget is 400")
	check(Data.Steps[2].Title == "Reach 400 speed!", "the step title says it", Data.Steps[2].Title)
	check(has(Data.Steps[2].Detail, "hit 400.") and not has(Data.Steps[2].Detail, "1,000"),
		"and its words", Data.Steps[2].Detail)
	check(Spot.Targets.speed.words == "YOUR SPEED \u{00B7} GET 400", "the spotlight says GET 400",
		Spot.Targets.speed.words)
	local ui = sourceOf(StarterPlayer:FindFirstChild("StarterPlayerScripts"), "TutorialUI")
	check(has(ui, '" / " .. Data.SpeedTargetText .. " SPEED"') and not has(ui, "1,000 SPEED"),
		"and the pointer counts toward Data.SpeedTargetText -- no 1,000 left in the guide's count")

	-- Old saves: Sanitise credits `speed` at or above the target, so a lower one
	-- only ever credits more players.
	local function v3(speed)
		return Schema.Sanitise({ Speed = speed,
			Tutorial = { Version = 3, Done = {}, Skipped = false, PodGrants = 0 } }).Tutorial.Done
	end
	local at400, at399, at999, at1000 = v3(400), v3(399), v3(999), v3(1000)
	check(at400.train == true and at400.speed == true, "a save at exactly 400 is credited train and speed")
	check(at999.speed == true and at1000.speed == true, "so are 999 and 1,000")
	check(at399.train == true and at399.speed ~= true, "399 has trained and is still on the speed step")
	check(at400.steal ~= true, "and nothing past the speed step is credited by Speed")
end

--==============================================================================
-- 2. WHO IS OWED A STARTER
--==============================================================================
say("\n-- who is owed a starter --")
do
	check(starterSpecies ~= nil and starterSpecies.Biome == "greenhollow" and starterSpecies.Rarity == "Common",
		"the starter is a Greenhollow Common", FirstMinute.StarterSpecies)
	check(FirstMinute.starter() == starterSpecies and FirstMinute.StarterTier == 1, "Tiny")
	check(FirstMinute.StarterSpecies ~= "nubkin", "and not the reserved pod's Nubkin, so the guide's hatch can still be NEW")
	check(SeedData.GrowSecondsFor(starterSpecies, 1) == 30, "on the normal Tiny timer: 30 s")

	local fresh = Schema.Default()
	check(FirstMinute.owed(fresh), "a brand-new profile is owed one")
	local function owedWith(change)
		local p = Schema.Default()
		change(p)
		return FirstMinute.owed(p)
	end
	check(not owedWith(function(p) p.Speed = 1 end), "not with any Speed")
	check(not owedWith(function(p)
		p.Plants = { { SpeciesId = "nubkin", Tier = 1, PlantedAt = 1, HatchAt = 2, X = 0, Z = 0, Stage = 1 } }
	end), "not with a plant")
	check(not owedWith(function(p) p.Held = { { Id = "nubkin", Tier = 1, Hatched = false, Item = "1" } } end),
		"not with anything in the Bag")
	check(not owedWith(function(p) p.Almanac = { nubkin = true } end), "not with an Almanac entry")
	check(not owedWith(function(p) p.Tutorial.Done.train = true end), "not with a step done")
	check(not owedWith(function(p) p.StarterAt = 1760000000 end), "and never a second time")
	check(not FirstMinute.owed(nil) and not FirstMinute.owed({}), "a missing or junk profile is owed nothing")
	check(owedWith(function(p) p.Cash = 500; p.Tutorial.Skipped = true end),
		"cash and a skipped guide are not on the owner's list, and change nothing")
end

--==============================================================================
-- THE STAND-INS FOR THE REAL PlantService
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = table.pack(...) })
end
local function count(name)
	local n = 0
	for _, t in trace do
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
local owner = { Name = "SpecNewcomer", UserId = 90000000101, Parent = fakePlayers }

local plots = {}
local currentPlot = nil
local assignedFn, releasedFn = nil, nil
local PlotService = {
	OwnerOf = function(plot)
		return if plot ~= nil and plots[plot] then owner else nil
	end,
	PlotOf = function(player)
		return if player == owner then currentPlot else nil
	end,
	OnAssigned = function(fn)
		assignedFn = fn
	end,
	OnReleased = function(fn)
		releasedFn = fn
	end,
	OnResizing = function() end,
	OnResized = function() end,
	LevelOf = function()
		return 1
	end,
}

local profile = Schema.Default()
local minted = 0
local PlayerDataService = {
	IsReady = function()
		return true
	end,
	Get = function(player)
		return if player == owner then profile else nil
	end,
	SetPlants = function(_player, list)
		record("SetPlants", list)
		profile.Plants = list
		return true
	end,
	MarkSeen = function(_player, id)
		record("MarkSeen", id)
		local was = profile.Almanac[id] == true
		profile.Almanac[id] = true
		return not was
	end,
	RecordTutorial = function(_player, step)
		record("RecordTutorial", step)
		return Data.Record(profile.Tutorial, step)
	end,
	MintItem = function()
		minted += 1
		record("MintItem")
		return "spec" .. minted
	end,
	RecordStarter = function(_player, at)
		record("RecordStarter", at)
		if (tonumber(profile.StarterAt) or 0) > 0 then
			return false
		end
		profile.StarterAt = math.floor(at)
		return true
	end,
	TakeFirstCatch = function(_player, id, tier)
		record("TakeFirstCatch", id, tier)
		return FirstMinute.takeCatch(profile, id, tier)
	end,
}

local CarryService = {
	GiveHatched = function(player, species, tier, _equipAfter, _revealAt, _onRecord, item)
		record("GiveHatched", player, species, tier, item)
		return true
	end,
	SyncHeldNow = function() end,
	HeldRoom = function()
		return 5, 0, true
	end,
	IsCarrying = function()
		return false
	end,
}

local fakeMarket = {}
function fakeMarket:PromptProductPurchase(player, productId)
	record("PromptProductPurchase", player, productId)
end

-- THE GAMEEVENT REMOTE, STOOD IN: what the clients would be sent is recorded
-- here, so the starter's reveal and its notice can be read back.
local fired = {}
local fakeChannel = {
	OnServerEvent = {
		Connect = function()
			return { Disconnect = function() end }
		end,
	},
}
function fakeChannel:IsA(class)
	return class == "RemoteEvent"
end
function fakeChannel:FireAllClients(action, payload)
	table.insert(fired, { to = "all", action = action, payload = payload })
end
function fakeChannel:FireClient(who, action, payload)
	table.insert(fired, { to = who, action = action, payload = payload })
end
local fakeRemotes = {}
function fakeRemotes:FindFirstChild(name)
	return if name == GameConfig.Remotes.GameEvent then fakeChannel else nil
end
local realSeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local fakeSeedGame = {}
function fakeSeedGame:WaitForChild(name)
	return realSeedGame:WaitForChild(name)
end
function fakeSeedGame:FindFirstChild(name)
	if name == "Remotes" then
		return fakeRemotes
	end
	return realSeedGame:FindFirstChild(name)
end
local fakeReplicated = {}
function fakeReplicated:WaitForChild(name)
	if name == "SeedGame" then
		return fakeSeedGame
	end
	return ReplicatedStorage:WaitForChild(name)
end

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "MarketplaceService" then
		return fakeMarket
	elseif name == "Players" then
		return fakePlayers
	elseif name == "ReplicatedStorage" then
		return fakeReplicated
	end
	return game:GetService(name)
end

-- A product id this spec owns, so an ordinary pod DOES carry Instant Hatch and
-- the starter's lack of one means something.
local SPEC_PRODUCT = 990011
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
-- The roll switched off (and no Studio preview): the reveal is immediate, as
-- HatchRevealSpec runs it. The roll itself is HatchRollSpec's.
local function rollConfig(on)
	local roll = setmetatable({ Enabled = on, StudioPreview = false },
		{ __index = GameConfig.Plant.Hatch.Roll })
	local hatchConfig = setmetatable({ Roll = roll }, { __index = GameConfig.Plant.Hatch })
	local plant = setmetatable({ Hatch = hatchConfig }, { __index = GameConfig.Plant })
	return setmetatable({ Plant = plant }, { __index = liveConfig })
end

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

local made = {}
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
		CFrame.lookAt(Vector3.new(0, 760, centreR), Vector3.new(0, 760, 0)))
	plot:SetAttribute("Depth", startDepth)
	MapService.ResizePlot(plot, 1)
	plots[plot] = true
	table.insert(made, plot)
	return plot
end

-- Hand a plot over the way PlotService does, and take the last one back first:
-- a rejoin is a release and a new assignment.
local function assign(plot)
	if currentPlot and releasedFn then
		releasedFn(owner, currentPlot)
	end
	currentPlot = plot
	assignedFn(owner, plot)
end

local function modelsIn(plot)
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

local function waitFor(fn, seconds)
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		if fn() then
			return true
		end
		task.wait(0.1)
	end
	return fn() == true
end

local function rowOf(speciesId)
	for _, row in profile.Plants do
		if row.SpeciesId == speciesId then
			return row
		end
	end
	return nil
end

local PlantService = nil
local revealsHeard = 0
local heardPayloads = {}

local function plantBody()
	local loaded, loadErr = pcall(function()
		local rollOff = loadWith(Shared.HatchRoll, {
			GameConfig = rollConfig(false),
			SeedData = SeedData,
		})
		PlantService = loadWith(Server.PlantService, {
			PlotService = PlotService,
			PlayerDataService = PlayerDataService,
			CarryService = CarryService,
			PlantWander = PlantWander,
			GardenFrame = require(Server:WaitForChild("GardenFrame")),
			-- The Mysterious Pod (2026-10-11): no shells in this fixture.
			MysteryPodService = { IsShell = function() return false end, Outcome = function() return nil end,
				Consume = function() end, TellHatch = function() end },
		}, { GameConfig = rollConfig(false), HatchRoll = rollOff })
		PlantService.Init()
		PlantService.Start()
	end)
	check(loaded and assignedFn ~= nil and releasedFn ~= nil,
		"PlantService loads and starts against the stand-ins", loadErr)
	if not (loaded and assignedFn) then
		return
	end
	PlantService.OnRevealed(function(payload)
		revealsHeard += 1
		table.insert(heardPayloads, payload)
	end)

	--==========================================================================
	-- 3. THE STARTER GOES IN, ONCE
	--==========================================================================
	say("\n-- the starter goes in --")
	local starterAt = 0
	do
		profile = Schema.Default()
		trace = {}
		assign(makePlot("FirstMinuteSpecA", 91))
		local row = profile.Plants[1]
		check(#profile.Plants == 1 and row ~= nil and row.SpeciesId == FirstMinute.StarterSpecies
				and row.Tier == 1 and row.Stage == CreatureModel.STAGE_POD,
			"a fresh profile's garden comes back with ONE Tiny starter pod in it",
			row and string.format("%d rows, %s T%s stage %s", #profile.Plants, tostring(row.SpeciesId),
				tostring(row.Tier), tostring(row.Stage)))
		check(row ~= nil and row.HatchAt - row.PlantedAt == 30, "on the normal 30 s",
			row and (row.HatchAt - row.PlantedAt))
		check(count("RecordStarter") == 1 and row ~= nil and profile.StarterAt == row.PlantedAt,
			"and the profile records it, stamped with the row's own PlantedAt",
			string.format("%d calls, StarterAt %s", count("RecordStarter"), tostring(profile.StarterAt)))
		starterAt = profile.StarterAt
		local pod = modelsIn(currentPlot)[1]
		check(pod ~= nil, "the pod is standing in the soil")
		check(pod ~= nil and promptNamed(pod, "HatchPrompt") == nil and promptNamed(pod, "InstantHatchPrompt") == nil,
			"with no Hatch prompt and nothing for sale on it")
		check(pod ~= nil and tonumber(pod:GetAttribute("HatchAt")) == row.HatchAt,
			"its clock is the ordinary HatchAt, so the countdown over it is the normal one")
		check(count("RecordTutorial") == 0, "planting it records no step")

		-- Not before its time.
		task.wait(GameConfig.Plant.TickSeconds * 1.6)
		check(count("MarkSeen") == 0 and (profile.Plants[1] or {}).Stage == CreatureModel.STAGE_POD,
			"a tick later it is still a pod: nothing hatches early")
	end

	--==========================================================================
	-- 4. A REJOIN NEVER GIVES A SECOND
	--==========================================================================
	say("\n-- a rejoin --")
	do
		trace = {}
		assign(makePlot("FirstMinuteSpecB", 92))
		check(#profile.Plants == 1 and count("RecordStarter") == 0,
			"rejoining with the starter still growing: the same one pod, no second",
			string.format("%d rows, %d RecordStarter", #profile.Plants, count("RecordStarter")))
		local pod = modelsIn(currentPlot)[1]
		check(pod ~= nil and promptNamed(pod, "HatchPrompt") == nil and promptNamed(pod, "InstantHatchPrompt") == nil,
			"and it is known again as the starter: still no prompt on it")
	end

	--==========================================================================
	-- 5. IT HATCHES BY ITSELF, IN PLACE, AND IS THEN AN ORDINARY PLANT
	--==========================================================================
	say("\n-- it hatches by itself --")
	local starterId = nil
	do
		-- Its 30 s, spent: the saved row and the stamp moved 31 s into the past.
		local now = os.time()
		local row = profile.Plants[1]
		row.PlantedAt = now - 31
		row.HatchAt = now - 1
		profile.StarterAt = row.PlantedAt
		starterAt = profile.StarterAt
		trace = {}
		table.clear(fired)
		revealsHeard = 0
		assign(makePlot("FirstMinuteSpecC", 93))
		local hatched = waitFor(function()
			local r = profile.Plants[1]
			return r ~= nil and r.Stage == CreatureModel.STAGE_GROWN
		end, GameConfig.Plant.TickSeconds * 3 + 1)
		local r = profile.Plants[1]
		check(hatched, "once its time is up the tick hatches it -- nobody holds anything")
		check(r ~= nil and r.SpeciesId == FirstMinute.StarterSpecies and r.Tier == 1 and r.PlantedAt == starterAt,
			"in place: the same row, now the grown creature", r and r.Stage)
		check(r ~= nil and type(r.Item) == "string" and count("MintItem") == 1,
			"with an item id of its own, like any planted creature", r and r.Item)
		check(count("GiveHatched") == 0, "nothing is handed to the Bag")
		check(count("RecordTutorial") == 0, "and it records NO tutorial milestone")
		check(count("MarkSeen") == 1 and profile.Almanac[FirstMinute.StarterSpecies] == true,
			"the Almanac learns it, as any reveal does")
		check(revealsHeard == 0, "no OnRevealed listener hears it, so no hatch bonus spin is paid for it",
			revealsHeard)
		local reveal = nil
		for _, f in fired do
			if f.to == "all" and f.action == HATCH.Action then
				reveal = f.payload
			end
		end
		check(reveal ~= nil and reveal.species == FirstMinute.StarterSpecies and reveal.tier == 1
				and reveal.owner == owner and reveal.starter == true and reveal.firstHatch == false,
			"the clients get the normal reveal, marked as the starter's",
			reveal and string.format("%s T%s starter=%s firstHatch=%s", tostring(reveal.species),
				tostring(reveal.tier), tostring(reveal.starter), tostring(reveal.firstHatch)))
		local income = SeedData.IncomePerSecond(starterSpecies, 1)
		check(reveal ~= nil and reveal.income == income and typeof(reveal.cf) == "CFrame",
			"with the plant's real income and where it stood", reveal and reveal.income)

		local noticed = waitFor(function()
			for _, f in fired do
				if f.to == owner and f.action == Notice.ServerNotice then
					return true
				end
			end
			return false
		end, GameConfig.Plant.BurstSeconds + HATCH.Reveal.Seconds + 1)
		local notice = nil
		for _, f in fired do
			if f.to == owner and f.action == Notice.ServerNotice then
				notice = f.payload
			end
		end
		local wanted = "It earns $" .. GameConfig.compact(income) .. "/s"
		check(noticed and notice ~= nil and notice.title == "Your first plant hatched!" and notice.detail == wanted,
			"the owner is told: \"Your first plant hatched! " .. wanted .. "\"",
			notice and (tostring(notice.title) .. " / " .. tostring(notice.detail)))
		local post = notice and Notice.readServerNotice(notice)
		check(post ~= nil and post.title == notice.title and post.detail == notice.detail,
			"in words the notice stack takes whole (no cut)")

		-- The burst untags the pod at once, so any Planted model in this garden
		-- now is the creature the hatch stood up.
		local stood = waitFor(function()
			for id in modelsIn(currentPlot) do
				starterId = id
				return true
			end
			return false
		end, HATCH.Reveal.Seconds + HATCH.Label.Seconds + HATCH.Label.FadeSeconds + 2)
		check(stood and starterId ~= nil, "and the real creature stands up where the reveal was")

		local grown = PlantService.GrownIn(currentPlot)
		check(#grown == 1 and grown[1].species == starterSpecies and grown[1].tier == 1,
			"it EARNS: the garden's earners are this one plant")
		trace = {}
		local lifted = starterId and PlantService.PickUpById(owner, starterId)
		local gave = last("GiveHatched")
		check(lifted == true and gave ~= nil and gave.args[2] == starterSpecies and gave.args[3] == 1
				and gave.args[4] == r.Item,
			"and it can be lifted like any other: to the Bag as itself, item id and all",
			gave and tostring(gave.args[4]))
		check(#profile.Plants == 0, "leaving the garden empty")
	end

	--==========================================================================
	-- 6. NEVER TO AN EXISTING PLAYER, AND NEVER TWICE
	--==========================================================================
	say("\n-- never to an existing player, never twice --")
	do
		-- After a progress reset: nothing at all, but StarterAt kept.
		local reset = Schema.Default()
		reset.StarterAt = starterAt
		profile = reset
		trace = {}
		assign(makePlot("FirstMinuteSpecD", 94))
		check(#profile.Plants == 0 and count("RecordStarter") == 0,
			"a profile that already had its starter gets none, even emptied by a reset")

		-- An existing player with a garden: an ordinary growing pod.
		local now = os.time()
		local existing = Schema.Default()
		existing.Speed = 250
		existing.Tutorial.Done.train = true
		existing.Plants = { { SpeciesId = "nubkin", Tier = 1, PlantedAt = now - 5, HatchAt = now + 25,
			X = 0, Z = -4, Stage = 1, Facing = 0 } }
		profile = existing
		trace = {}
		assign(makePlot("FirstMinuteSpecE", 95))
		check(#profile.Plants == 1 and profile.Plants[1].SpeciesId == "nubkin" and count("RecordStarter") == 0,
			"an existing player's garden comes back exactly as it was, with no starter added")
		local pod = modelsIn(currentPlot)[1]
		check(pod ~= nil and promptNamed(pod, "InstantHatchPrompt") ~= nil,
			"and their own growing pod keeps its Instant Hatch prompt (the starter's absence above is real)")

		-- A player who joined once and did nothing at all, before this update:
		-- brand-new by every item of the owner's list, so owed their one starter.
		local idle = Schema.Sanitise({ Speed = 0, Tutorial = { Version = 3, Done = {}, Skipped = true } })
		profile = idle
		trace = {}
		assign(makePlot("FirstMinuteSpecF", 96))
		check(#profile.Plants == 1 and count("RecordStarter") == 1,
			"a save with nothing in it at all is brand-new by the list, and gets its one")
	end

	--==========================================================================
	-- 7. THE FIRST CATCH'S REVEAL
	--==========================================================================
	say("\n-- the first catch's reveal --")
	do
		local now = os.time()
		local p = Schema.Default()
		p.Speed = 450
		for _, id in { "train", "speed", "steal", "bank", "place" } do
			Data.Record(p.Tutorial, id)
		end
		p.FirstCatchSpecies, p.FirstCatchTier = "nubkin", 2
		local function ready(tier, x)
			return { SpeciesId = "nubkin", Tier = tier, PlantedAt = now - 120, HatchAt = now - 1,
				X = x, Z = -4, Stage = 1, Facing = 0 }
		end
		p.Plants = { ready(1, -8), ready(2, 0), ready(2, 8) }
		profile = p
		table.clear(heardPayloads)
		assign(makePlot("FirstMinuteSpecG", 97))
		local ok1 = PlantService.HatchByHand(owner, currentPlot, 1)
		local ok2 = PlantService.HatchByHand(owner, currentPlot, 2)
		local ok3 = PlantService.HatchByHand(owner, currentPlot, 3)
		check(ok1 and ok2 and ok3 and #heardPayloads == 3, "three ready Nubkins hatched by hand",
			#heardPayloads)
		local a, b, c = heardPayloads[1], heardPayloads[2], heardPayloads[3]
		check(a and a.firstCatch == false, "a Tiny Nubkin is not the Big one that was caught")
		check(b and b.firstCatch == true and b.tier == 2,
			"the first Big Nubkin's reveal says it: \"" .. FirstMinute.catchWords(2) .. "\"")
		check(c and c.firstCatch == false, "once: the next Big Nubkin is just a Big Nubkin")
		check(profile.FirstCatchSpecies == "" and profile.FirstCatchTier == 0, "and the note is gone from the record")
	end
end

--==============================================================================
-- RUN THE PLANT HALF
--==============================================================================
local plantOk, plantErr = pcall(plantBody)
if not plantOk then
	fail += 1
	say("  FAIL  the PlantService half threw  <- " .. tostring(plantErr))
end
if PlantService then
	pcall(PlantService.Init)
end
for _, plot in made do
	plot:Destroy()
end

--==============================================================================
-- 8. NOT TUTORIAL PROGRESS, ON ANY LOAD PATH
--==============================================================================
say("\n-- not tutorial progress --")
do
	local T = 1760000000
	local function load(extra)
		local raw = { Speed = 0, StarterAt = T,
			Tutorial = { Version = 3, Done = {}, Skipped = false, PodGrants = 0 } }
		for k, v in extra do
			raw[k] = v
		end
		return Schema.Sanitise(raw)
	end
	local function noneDone(done)
		return next(done) == nil
	end
	local growing = load({ Plants = { { SpeciesId = "petalpip", Tier = 1, PlantedAt = T, HatchAt = T + 30,
		X = 0, Z = 0, Stage = 1 } } })
	check(noneDone(growing.Tutorial.Done), "the starter growing proves no step (a planted pod used to prove `place`)")
	local grownProfile = load({ Plants = { { SpeciesId = "petalpip", Tier = 1, PlantedAt = T, HatchAt = T + 30,
		X = 0, Z = 0, Stage = 3, Item = "1" } }, Almanac = { petalpip = true } })
	check(noneDone(grownProfile.Tutorial.Done),
		"nor does it grown, with its Almanac entry (a grown plant used to finish the whole first loop)")
	local lifted = load({ Held = { { Id = "petalpip", Tier = 1, Hatched = true, Item = "1" } },
		Almanac = { petalpip = true } })
	check(noneDone(lifted.Tutorial.Done), "nor lifted into the Bag as a hatched plant")
	local trained = load({ Speed = 120, Plants = { { SpeciesId = "petalpip", Tier = 1, PlantedAt = T,
		HatchAt = T + 30, X = 0, Z = 0, Stage = 3 } } })
	check(trained.Tutorial.Done.train == true and trained.Tutorial.Done.steal ~= true,
		"Speed still proves training on such a profile, and only that")
	check(not Data.FirstLoopDone(grownProfile.Tutorial) and Data.Current(grownProfile.Tutorial) == 1,
		"the guide still starts at the treadmill")

	-- The same possessions on a save from before the starter existed still read
	-- exactly as they always did.
	local old = Schema.Sanitise({ Speed = 0, Plants = { { SpeciesId = "petalpip", Tier = 1, PlantedAt = T,
		HatchAt = T + 30, X = 0, Z = 0, Stage = 3 } }, Almanac = { petalpip = true },
		Tutorial = { Version = 2, Done = {}, Skipped = false } })
	check(Data.FirstLoopDone(old.Tutorial),
		"without StarterAt, a grown plant still proves the first loop -- old saves are untouched")

	-- HasOutstandingPod: the starter is not "a pod they already have".
	local starterRow = { SpeciesId = "petalpip", Tier = 1, PlantedAt = T, HatchAt = T + 30, Stage = 1 }
	local stolenRow = { SpeciesId = "nubkin", Tier = 2, PlantedAt = T + 90, HatchAt = T + 150, Stage = 1 }
	check(not Data.HasOutstandingPod({ carrying = false, inWorld = false, held = {}, plants = { starterRow },
		starterAt = T }), "HasOutstandingPod: the growing starter does not count")
	check(Data.HasOutstandingPod({ carrying = false, inWorld = false, held = {}, plants = { starterRow, stolenRow },
		starterAt = T }), "a real pod beside it still does")
	check(Data.HasOutstandingPod({ carrying = false, inWorld = false, held = {}, plants = { starterRow } }),
		"and without the stamp the old reading is unchanged")
	local stealStep = Data.Default()
	Data.Record(stealStep, "train")
	Data.Record(stealStep, "speed")
	check(Data.PodEligible(stealStep) and not Data.HasOutstandingPod({ carrying = false, inWorld = false,
		held = {}, plants = { starterRow }, starterAt = T }),
		"so at the steal step, with the starter still growing, the reserved pod is still offered")
	local podSrc = sourceOf(Server, "TutorialPodService")
	check(has(podSrc, "starterAt = (profile :: any).StarterAt"),
		"TutorialPodService hands the stamp to HasOutstandingPod")

	-- THE BONUS CHEST, the real Claim on a profile whose starter has grown.
	local chestModule = Server.BonusChestService
	local chestChunk, chestErr = loadstring(chestModule.Source)
	assert(chestChunk, chestErr)
	local chestProfile = grownProfile
	local fakeData = {
		Get = function()
			return chestProfile
		end,
		IsPersistent = function()
			return true
		end,
		SetChest = function(_, nextAt, boost, endsAt)
			chestProfile.ChestNextAt, chestProfile.ChestBoost, chestProfile.ChestBoostEndsAt = nextAt, boost, endsAt
			return true
		end,
		Save = function()
			return true
		end,
	}
	local chestEnv = {
		script = chestModule,
		print = function() end,
		require = function(target)
			if target.Name == "PlayerDataService" then
				return fakeData
			end
			if target.Name == "Metrics" then
				return { chestClaimed = function() end }
			end
			return require(target)
		end,
	}
	setmetatable(chestEnv, { __index = getfenv(1) })
	setfenv(chestChunk, chestEnv)
	local Chest = chestChunk()
	local chestPlayer = {
		Parent = Players,
		Name = "SpecChest",
		UserId = 90000000102,
		GetAttribute = function()
			return nil
		end,
		SetAttribute = function() end,
	}
	if GameConfig.BonusChest.Enabled then
		local _, code = Chest.Claim(chestPlayer)
		check(code == "LOCKED", "the Bonus Chest stays LOCKED for a garden that only has the starter", code)
	end
end

--==============================================================================
-- 9. THE FIRST RAID AT 400
--==============================================================================
say("\n-- the first raid --")
do
	local FAIR = green.FirstRaidChaseSpeed
	local RAGE = P.RageSpeedPerTake
	local USUAL = green.GuardianChaseSpeed + RAGE
	check(FAIR == 19 and USUAL == 20 and RAGE == 5, "Greenhollow: a first raid chases at most at 19; the usual first theft at 20")
	for _, biome in BiomeData.Biomes do
		if biome.Id ~= "greenhollow" then
			check(biome.FirstRaidChaseSpeed == nil, biome.Id .. " names no first-raid speed")
		end
	end

	local runHome = 0
	for _, cf in BiomeData.NestCFrames(green) do
		runHome = math.max(runHome, math.abs(cf.Position.Z + GameConfig.Map.FieldFront))
	end
	check(runHome > 200, "the run home is the real one: " .. math.floor(runHome) .. " studs")

	local function escapes(walk, guardian)
		local gap = walk * P.WakeDelaySeconds
		local travelled = gap
		local dt, t = 1 / 50, 0
		while travelled < runHome and gap > P.GrabStuds and t < 200 do
			gap += (walk - guardian) * dt
			travelled += walk * dt
			t += dt
		end
		return travelled >= runHome
	end
	local function walk(score, carry)
		return GameConfig.walkSpeedFor(score) * carry
	end

	-- THE LIVE CARRY: CarryService multiplies by carryMultiplierFor of the SIZE
	-- (1-7). Today's beginner: 1,000 Speed, a Tiny, against 20.
	local today = walk(1000, GameConfig.carryMultiplierFor(1)) - USUAL
	local worst, bestOk = math.huge, true
	for tier = FirstMinute.CatchTier, SeedData.TierCount do
		local mine = walk(Data.SpeedTarget, GameConfig.carryMultiplierFor(tier))
		worst = math.min(worst, mine - FAIR)
		if not escapes(mine, FAIR) then
			bestOk = false
		end
	end
	check(worst >= today and worst >= 1.5,
		string.format("at exactly 400, any first catch (Big to Colossal) gains %.2f studs/s at 19 -- today's beginner gains %.2f at 20",
			worst, today))
	check(bestOk, "and gets home over the real route, whatever size it is carrying")
	-- THE CONSERVATIVE READING behind BiomeData's "about 1.5": a light pod of 30.
	local light = GameConfig.carryMultiplierFor(30)
	local todayLight = walk(1000, light) - USUAL
	check(walk(Data.SpeedTarget, light) - FAIR >= todayLight and escapes(walk(Data.SpeedTarget, light), FAIR),
		string.format("read the old way too: %.2f at 400 against today's %.2f",
			walk(Data.SpeedTarget, light) - FAIR, todayLight))
	check(not escapes(walk(0, GameConfig.carryMultiplierFor(FirstMinute.CatchTier)), FAIR),
		"a player at Speed 0 is still caught on a first raid -- the lesson survives")
	check(not escapes(walk(Data.SpeedTarget, GameConfig.carryMultiplierFor(2)), green.GuardianChaseSpeed + RAGE * 2),
		"and a second theft before the nest calms (25) still takes it back")

	-- THE REAL provoke, on nest records built here.
	local fixture = Instance.new("Folder")
	fixture.Name = "FirstMinuteSpecFixture"
	fixture.Parent = ServerStorage
	local serial = 0
	local function makeNest(biome)
		serial += 1
		local model = Instance.new("Model")
		model.Name = "SpecGuardian"
		model.Parent = fixture
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Anchored = true
		root.Position = Vector3.new(serial * 30, 900, 0)
		root.Parent = model
		return {
			id = "Nest_firstminute_" .. serial, biome = biome, origin = root.Position,
			homeCFrame = CFrame.new(root.Position), parent = model, root = root, folder = fixture,
			slots = {}, pods = {},
			humanoid = { WalkSpeed = 0, MoveTo = function() end },
			state = "returning", target = nil, stateUntil = 0, busy = false, rage = 0, calmSince = 0,
			chaseSince = 0, haul = nil, sample = nil, thieves = {},
		}
	end
	local beginner = { Name = "SpecBeginner", UserId = 90000000201, Parent = Players }
	local veteran = { Name = "SpecVeteran", UserId = 90000000202, Parent = Players }
	local unknown = { Name = "SpecUnknown", UserId = 90000000203, Parent = Players }
	local raidOk, raidErr = pcall(function()
		NestService.SpecStealDone(function(player)
			if player == beginner then
				return false
			elseif player == veteran then
				return true
			end
			return nil
		end)

		local nest = makeNest(green)
		NestService.SpecProvoke(nest, beginner, false)
		check(nest.firstRaid == beginner and nest.rage == 1 and nest.target == beginner,
			"a beginner's theft from a calm Greenhollow nest (the reserved pod's path) starts a first raid")
		check(NestService.SpecChaseSpeed(nest) == FAIR and nest.humanoid.WalkSpeed == FAIR,
			"and the guardian is told 19 the moment it gives chase", nest.humanoid.WalkSpeed)
		local fromRing = makeNest(green)
		NestService.SpecProvoke(fromRing, beginner, true)
		check(NestService.SpecChaseSpeed(fromRing) == FAIR, "the same for a pod out of the ring")

		NestService.SpecProvoke(nest, beginner, false)
		check(nest.rage == 2 and NestService.SpecChaseSpeed(nest) == USUAL + RAGE and nest.humanoid.WalkSpeed == USUAL + RAGE,
			"a second theft before it calms: 25, Greenhollow's rage exactly as before", NestService.SpecChaseSpeed(nest))

		local other = makeNest(green)
		NestService.SpecProvoke(other, veteran, false)
		check(other.target == veteran and other.firstRaid == nil and NestService.SpecChaseSpeed(other) == USUAL,
			"a player whose steal is done is chased at 20, as ever", NestService.SpecChaseSpeed(other))

		local unsure = makeNest(green)
		NestService.SpecProvoke(unsure, unknown, false)
		check(unsure.firstRaid == nil and NestService.SpecChaseSpeed(unsure) == USUAL,
			"so is a thief whose record has not arrived -- not knowing is not a beginner")

		local angry = makeNest(green)
		angry.rage = 1
		NestService.SpecProvoke(angry, beginner, false)
		check(angry.firstRaid == nil and NestService.SpecChaseSpeed(angry) == USUAL + RAGE,
			"a beginner robbing a nest still angry from someone else meets its rage (25), as today")

		local switched = makeNest(green)
		NestService.SpecProvoke(switched, beginner, false)
		switched.target = veteran
		check(NestService.SpecChaseSpeed(switched) == USUAL,
			"when the chase turns to anybody else, it is 20 again")

		local secret = makeNest(green)
		secret.secret = { id = "spec-secret" }
		NestService.SpecProvoke(secret, beginner, true, "spec-secret")
		check(secret.firstRaid == nil and NestService.SpecChaseSpeed(secret) == green.Secret.ChaseSpeed + RAGE,
			"the Secret's thief, beginner or not, meets the Secret's own numbers", NestService.SpecChaseSpeed(secret))

		local dustA, dustB = makeNest(dustbowl), makeNest(dustbowl)
		NestService.SpecProvoke(dustA, beginner, true)
		NestService.SpecProvoke(dustB, veteran, true)
		check(dustA.firstRaid == nil and NestService.SpecChaseSpeed(dustA) == NestService.SpecChaseSpeed(dustB),
			"another biome is untouched: a beginner there meets what anybody does")
	end)
	check(raidOk, "the real provoke ran", raidErr)
	NestService.SpecStealDone(nil)
	fixture:Destroy()

	local nestSrc = sourceOf(Server, "NestService")
	check(has(nestSrc, "return if fair then math.min(fair, speed) else speed"),
		"the first raid can only lower a chase, never raise one")
	check(occurrences(nestSrc, "ruleSpeedFor(") == 2,
		"and every chase speed goes through chaseSpeedFor (ruleSpeedFor is called in one place)")
end

--==============================================================================
-- 10. THE FIRST CATCH IS BIG OR BIGGER, ONCE
--==============================================================================
say("\n-- the first catch --")
do
	check(FirstMinute.catchTier(1) == 2, "a Tiny becomes Big")
	check(FirstMinute.catchTier(2) == 2 and FirstMinute.catchTier(5) == 5 and FirstMinute.catchTier(7) == 7,
		"anything bigger stays as it rolled")
	check(FirstMinute.catchTier(0) == 2 and FirstMinute.catchTier(99) == 7 and FirstMinute.catchTier(nil) == 2,
		"junk reads a real size")
	check(SeedData.GrowSeconds(FirstMinute.catchTier(1)) == 60, "a Big grows in 60 s on the owner's ladder")
	check(FirstMinute.catchWords(2) == "BIG! Your first catch." and FirstMinute.catchWords(3) == "HUGE! Your first catch.",
		"its reveal's words: \"BIG! Your first catch.\"")
	local note = { FirstCatchSpecies = "nubkin", FirstCatchTier = 2 }
	check(not FirstMinute.takeCatch(note, "nubkin", 1) and not FirstMinute.takeCatch(note, "petalpip", 2),
		"another size or species is not it")
	check(FirstMinute.takeCatch(note, "nubkin", 2) and not FirstMinute.takeCatch(note, "nubkin", 2),
		"the match is taken once")

	local carrySrc = sourceOf(Server, "CarryService")
	check(has(carrySrc, 'PlayerDataService.TutorialDone(player, "steal") == false')
			and has(carrySrc, "and secretId == nil and eventId == nil"),
		"CarryService: only while `steal` is not done, and never for a Secret or an event pod")
	check(has(carrySrc, "local carriedTier = if firstCatch then FirstMinute.catchTier(takenTier) else takenTier")
			and has(carrySrc, "CreatureModel.BuildPod(taken, carriedTier, root.CFrame, character)")
			and has(carrySrc, "tier = carriedTier,"),
		"the size it is carried, built and banked at is the caught size")
	local noteAt = string.find(carrySrc, "PlayerDataService.RecordFirstCatch(player, taken.Id, carriedTier)", 1, true)
	local stealAt = string.find(carrySrc, 'PlayerDataService.RecordTutorial(player, "steal")', 1, true)
	check(noteAt ~= nil and stealAt ~= nil and noteAt < stealAt,
		"the catch is written down before `steal` is recorded -- which is what makes it once")
	local fxSrc = sourceOf(StarterPlayer:FindFirstChild("StarterPlayerScripts"), "HatchFX")
	check(has(fxSrc, "if payload.firstCatch == true then FirstMinute.catchWords(tier) else nil"),
		"HatchFX writes the words over the reveal, from the server's flag")
end

--==============================================================================
-- 11. THE SAVES
--==============================================================================
say("\n-- the saves --")
do
	local d = Schema.Default()
	check(d.StarterAt == 0 and d.FirstCatchSpecies == "" and d.FirstCatchTier == 0, "a new profile: 0, \"\", 0")
	local old = Schema.Sanitise({ Cash = 10, Speed = 20 })
	check(old.StarterAt == 0 and old.FirstCatchSpecies == "" and old.FirstCatchTier == 0,
		"an old save with none of the fields reads 0, \"\", 0")
	local junk = Schema.Sanitise({ StarterAt = "soon", FirstCatchSpecies = "notaspecies", FirstCatchTier = 0 / 0 })
	check(junk.StarterAt == 0 and junk.FirstCatchSpecies == "" and junk.FirstCatchTier == 0, "junk reads the same")
	local neg = Schema.Sanitise({ StarterAt = -5, FirstCatchSpecies = "nubkin", FirstCatchTier = 0 })
	check(neg.StarterAt == 0 and neg.FirstCatchSpecies == "" and neg.FirstCatchTier == 0,
		"a negative stamp is none, and a species with no size is no note")
	local kept = Schema.Sanitise({ StarterAt = 1760000123.7, FirstCatchSpecies = "nubkin", FirstCatchTier = 2 })
	check(kept.StarterAt == 1760000123 and kept.FirstCatchSpecies == "nubkin" and kept.FirstCatchTier == 2,
		"real values survive the load")
	local dataSrc = sourceOf(Server, "PlayerDataService")
	check(has(dataSrc, "StarterAt = math.max(0, math.floor(tonumber(profile.StarterAt) or 0)),"),
		"a progress reset keeps StarterAt: one starter per profile, ever")

	-- A v3 tutorial record with a full garden loads exactly as before.
	local T = 1760000000
	local full = {
		Speed = 5000, Cash = 123456,
		Tutorial = { Version = 3, Done = { train = true, speed = true, steal = true, bank = true },
			Skipped = false, PodGrants = 1 },
		Plants = {
			{ SpeciesId = "nubkin", Tier = 2, PlantedAt = T, HatchAt = T + 60, X = 1, Z = 2, Stage = 3, Item = "7" },
			{ SpeciesId = "petalpip", Tier = 1, PlantedAt = T + 9, HatchAt = T + 39, X = -3, Z = 4, Stage = 1 },
		},
		Held = { { Id = "spiretip", Tier = 3, Hatched = true, Item = "8" }, { Id = "nubkin", Tier = 1, Hatched = false, Item = "9" } },
		Almanac = { nubkin = true, spiretip = true },
	}
	local p = Schema.Sanitise(full)
	local want = { train = true, speed = true, steal = true, bank = true, place = true, hatch = true }
	local same = true
	for _, step in Data.Steps do
		if (p.Tutorial.Done[step.Id] == true) ~= (want[step.Id] == true) then
			same = false
		end
	end
	check(same and p.Tutorial.Done.travel ~= true,
		"a v3 record plus a full garden: credited through the hatch by its garden, travel still open -- as before")
	check(#p.Plants == 2 and #p.Held == 2 and p.Almanac.nubkin == true and p.Almanac.spiretip == true
			and p.Speed == 5000 and p.Cash == 123456 and p.Tutorial.PodGrants == 1,
		"every plant, Bag row, Almanac entry and number comes back")
	check(p.StarterAt == 0 and not FirstMinute.owed(p), "and it is never owed a starter")
	local again = Schema.Sanitise(p)
	check(#again.Plants == 2 and again.Tutorial.Done.hatch == true and again.Tutorial.Done.travel ~= true,
		"and loads the same again")
end

--==============================================================================
-- 12. WHAT THIS DID NOT TOUCH
--==============================================================================
say("\n-- untouched --")
do
	local ladder = { 30, 60, 150, 360, 900, 2100, 4500 }
	local ladderOk = true
	for tier = 1, 7 do
		if SeedData.GrowSeconds(tier) ~= ladder[tier] then
			ladderOk = false
		end
	end
	check(ladderOk, "the grow ladder is 30 / 60 / 150 / 360 / 900 / 2100 / 4500")
	local nubkin = SeedData.Get("nubkin")
	check(SeedData.IncomePerSecond(nubkin, 1) == 4 and SeedData.IncomePerSecond(nubkin, 2) == 28
			and SeedData.IncomePerSecond(starterSpecies, 1) == 5,
		"income: a Tiny Nubkin $4/s, a Big $28/s, the Tiny Petalpip starter $5/s",
		string.format("%s %s %s", SeedData.IncomePerSecond(nubkin, 1), SeedData.IncomePerSecond(nubkin, 2),
			SeedData.IncomePerSecond(starterSpecies, 1)))
	check(green.GuardianChaseSpeed == 15 and green.Secret.ChaseSpeed == 19 and green.RecommendedSpeed == 0,
		"Greenhollow's own numbers are as they were: 15, the Secret's 19, recommends nothing")
end

say(string.format("\nFirstMinuteSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
