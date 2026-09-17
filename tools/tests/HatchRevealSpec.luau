--!nocheck
--==============================================================================
-- Steal a Seed :: HatchRevealSpec
--
-- The hatch animation, and the rule it exists under: THE ANIMATION DECIDES
-- NOTHING. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HatchRevealSpec"))
--
-- What is asserted here is the ORDER and the PAYLOAD, because those are what a
-- player loses money over: the Tool exists and the garden is saved before a
-- single frame is drawn, and the one message that starts the animation carries
-- everything a client needs so that nothing has to be asked for afterwards.
--
-- The paid path is the one driven here, because a receipt can be delivered by a
-- function call and a held key cannot: ProximityPrompt.Triggered is the engine's
-- and no spec can fire it. Both paths run the SAME hatch(), which section 5
-- checks by reading the source, and the free hold is a Play test.
--
-- Not here: what any of it looks like (Play, and the owner's eyes), the camera
-- bump, and the sounds (Play -- and three of them have no asset yet).
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

--==============================================================================
-- 1. THE NUMBERS
--==============================================================================
say("\n-- the shape of it --")
do
	check(GameConfig.Plant.BurstSeconds == 0.35,
		"the shell bursts in 0.35s", GameConfig.Plant.BurstSeconds)
	check(HATCH.Reveal.Seconds == 0.8, "the creature comes up over 0.8s", HATCH.Reveal.Seconds)
	check(HATCH.Label.Seconds == 1.5, "the label holds for 1.5s", HATCH.Label.Seconds)
	check(HATCH.Paid.PulseSeconds == 0.15,
		"a purchase adds a 0.15s pulse and no hold", HATCH.Paid.PulseSeconds)
	local free = GameConfig.Plant.BurstSeconds + HATCH.Reveal.Seconds
	check(free > 1.1 and free < 1.25, string.format("a free hatch animates in %.2fs", free))
	check(free + HATCH.Paid.PulseSeconds <= 1.35,
		string.format("a paid one in %.2fs", free + HATCH.Paid.PulseSeconds))
	check(HATCH.Reveal.ScaleStart == 0.65, "it starts at 65% scale", HATCH.Reveal.ScaleStart)
	check(HATCH.Burst.Compress == 0.92, "after the shell squeezes to 92%", HATCH.Burst.Compress)
	check(HATCH.Reveal.LeanDegrees > 0 and HATCH.Reveal.LeanDegrees <= 15,
		"and leans, rather than turning", HATCH.Reveal.LeanDegrees)

	-- Tier intensity: stronger, never longer.
	local rows = HATCH.Tiers
	check(#rows == SeedData.TierCount, "one intensity row per tier", #rows)
	local rising, bumps, bolts = true, true, true
	for i, row in ipairs(rows) do
		if i > 1 then
			if row.ringScale <= rows[i - 1].ringScale or row.particles <= rows[i - 1].particles then
				rising = false
			end
		end
		-- A camera bump is the owner's, and only for the top two.
		if (i <= 5 and row.bump ~= 0) or (i >= 6 and row.bump <= 0) then
			bumps = false
		end
		if (i < 7 and row.lightning) or (i == 7 and not row.lightning) then
			bolts = false
		end
		if row.particles > 80 then
			rising = false
		end
	end
	check(rising, "every tier is a bigger event than the one below, and capped at 80 particles")
	check(bumps, "the camera moves for a Titan and a Colossal and nobody else")
	check(bolts, "only a Colossal cracks")
	check(rows[7].rings == 2 and rows[6].rings == 2 and rows[1].rings == 1,
		"the top two throw two rings")

	check(HATCH.Action ~= nil and HATCH.Action ~= "", "the reveal has a verb of its own", HATCH.Action)
	check(HATCH.HearingStuds > 0 and HATCH.HearingStuds <= 300,
		"and a range past which a client ignores it", HATCH.HearingStuds)

	-- The three sounds this animation would like and does not have. They are
	-- named and SILENT: naming them is the ask, and an empty string plays nothing.
	local silent = {}
	for name, cue in pairs(HATCH.Sounds) do
		if cue == "" then
			table.insert(silent, name)
		end
	end
	table.sort(silent)
	check(#silent == 3 and table.concat(silent, ",") == "Crack,Rattle,TimeSkip",
		"the rattle, the crack and the time-skip are declared and silent",
		table.concat(silent, ","))
	check(GameConfig.Sfx.RevealFor.Mythic ~= nil and GameConfig.Sfx.RevealFor.Common ~= nil,
		"while the rarity fanfare, which does exist, is mapped for every rarity")
end

--==============================================================================
-- THE STAND-INS
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end
local function indexOf(name)
	for i, t in ipairs(trace) do
		if t.name == name then
			return i
		end
	end
	return nil
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
local owner = { Name = "SpecOwner", UserId = 8181, Parent = fakePlayers }
local stranger = { Name = "SpecStranger", UserId = 9191, Parent = fakePlayers }

local plotModel = nil
local assignedFn = nil
local PlotService = {
	OwnerOf = function(plot)
		return if plot ~= nil and plot == plotModel then owner else nil
	end,
	PlotOf = function(playerArg)
		return if playerArg == owner then plotModel else nil
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

-- MarkSeen is SET-ONCE in the real service, and the reveal's NEW DISCOVERY line
-- is exactly its return value, so the stand-in has to behave the same way.
local seen = {}
local profile = { Plants = {} }
local PlayerDataService = {
	IsReady = function()
		return true
	end,
	Get = function(playerArg)
		return if playerArg == owner then profile else nil
	end,
	SetPlants = function(playerArg, list)
		record("SetPlants", playerArg, list)
	end,
	MarkSeen = function(playerArg, id)
		record("MarkSeen", playerArg, id)
		if seen[id] then
			return false
		end
		seen[id] = true
		return true
	end,
	RecordTutorial = function(playerArg, step)
		record("RecordTutorial", playerArg, step)
	end,
}

local giveWorks = true
local CarryService = {
	GiveHatched = function(playerArg, species, tier, equipAfter)
		record("GiveHatched", playerArg, species, tier, equipAfter)
		return giveWorks
	end,
	SyncHeldNow = function() end,
}

local fakeMarket = {}
function fakeMarket:PromptProductPurchase(playerArg, productId)
	record("PromptProductPurchase", playerArg, productId)
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

local SPEC_PRODUCT = 990009
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

local PlantService = nil
local reveals = {}

local function modelFor(id)
	for _, d in ipairs(plotModel:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("PlacementId") == id
			and CollectionService:HasTag(d, GameConfig.Tags.Planted) then
			return d
		end
	end
	return nil
end

local function body()
	plotModel = Instance.new("Model")
	plotModel.Name = "HatchRevealSpecPlot"
	plotModel.Archivable = false
	plotModel:SetAttribute("PreviewOnly", true)
	plotModel:SetAttribute(GameConfig.Attributes.PlotId, 94)
	plotModel.Parent = workspace
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	plotModel:SetAttribute("PlotCF",
		CFrame.lookAt(Vector3.new(0, 880, centreR), Vector3.new(0, 880, 0)))
	plotModel:SetAttribute("Depth", startDepth)
	MapService.ResizePlot(plotModel, 1)

	local now = os.time()
	-- 1: a Colossal still growing, which is what a purchase is for.
	-- 2: a second growing pod, so the paid pick has to choose.
	-- 3: a ready pod of the same species as 1, to prove the discovery flag flips.
	profile.Plants = {
		{ SpeciesId = "dunebud", Tier = 7, PlantedAt = now, HatchAt = now + 4000,
			X = -8, Z = -4, Stage = 1, Facing = 0 },
		{ SpeciesId = "nubkin", Tier = 2, PlantedAt = now, HatchAt = now + 50,
			X = 0, Z = -4, Stage = 1, Facing = 0 },
		{ SpeciesId = "dunebud", Tier = 1, PlantedAt = now - 60, HatchAt = now + 900,
			X = 8, Z = -4, Stage = 1, Facing = 0 },
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
	check(loadOk and assignedFn ~= nil,
		"PlantService loads and starts against the stand-ins", loadErr)
	if not (loadOk and assignedFn) then
		return
	end

	check(type(PlantService.OnRevealed) == "function",
		"and offers OnRevealed, so the server side of a hatch is observable")
	PlantService.OnRevealed(function(payload)
		table.insert(reveals, payload)
		record("Reveal", payload)
	end)

	assignedFn(owner, plotModel)
	local podOne = modelFor(1)
	check(podOne ~= nil, "the Colossal pod is in the bed")

	--==========================================================================
	-- 2. THE ORDER
	--==========================================================================
	say("\n-- the order --")
	do
		trace = {}
		check(PlantService.OfferInstantHatch(owner, plotModel, 1),
			"the owner presses Instant Hatch on the Colossal")
		check(PlantService.InstantHatch(owner), "and the receipt hatches it")

		local gave = indexOf("GiveHatched")
		local saved = indexOf("SetPlants")
		local marked = indexOf("MarkSeen")
		local taught = indexOf("RecordTutorial")
		local revealed = indexOf("Reveal")
		check(gave ~= nil and saved ~= nil and revealed ~= nil,
			"the Tool, the save and the reveal all happened",
			string.format("%s %s %s", tostring(gave), tostring(saved), tostring(revealed)))
		check(gave and saved and gave < saved, "the Tool exists BEFORE the garden is saved")
		check(saved and marked and saved < marked, "the garden is saved before the Almanac")
		check(marked and taught and marked < taught, "and the tutorial after it")
		check(taught and revealed and taught < revealed,
			"and the reveal is announced LAST, after everything that can be lost")

		local give = last("GiveHatched")
		local waitFor = if give then give.args[4] else nil
		check(type(waitFor) == "number" and waitFor > GameConfig.Plant.BurstSeconds,
			"the hand is asked to wait until the reveal is over", waitFor)
		check(type(waitFor) == "number"
				and math.abs(waitFor - (GameConfig.Plant.BurstSeconds + HATCH.Reveal.Seconds
					+ HATCH.Paid.PulseSeconds)) < 0.001,
			"which for a paid hatch is the pulse, the burst and the rise", waitFor)
		check(count("Reveal") == 1, "exactly one reveal was announced", count("Reveal"))
	end

	--==========================================================================
	-- 3. THE PAYLOAD
	--==========================================================================
	say("\n-- what the clients are told --")
	do
		local payload = reveals[1]
		local species = SeedData.Get("dunebud")
		check(payload ~= nil and payload.species == "dunebud" and payload.tier == 7,
			"which species and which tier", payload and payload.species)
		check(payload ~= nil and payload.rarity == species.Rarity,
			"the species' rarity, not the weight band", payload and payload.rarity)
		check(payload ~= nil
				and math.abs(payload.income - SeedData.IncomePerSecond(species, 7)) < 0.001,
			"the income the garden itself would pay", payload and payload.income)
		check(payload ~= nil and typeof(payload.cf) == "CFrame",
			"where the pod stood", payload and typeof(payload.cf))
		check(payload ~= nil and payload.owner == owner, "and whose it was")
		check(payload ~= nil and payload.paid == true, "this one was paid for")
		check(payload ~= nil and payload.discovery == true,
			"and it was the first Dunebud this player ever hatched")
		check(payload ~= nil and type(payload.at) == "number" and payload.at > 0,
			"stamped with server time, so every client starts together", payload and payload.at)
		check(payload ~= nil and type(payload.token) == "number",
			"and carries a token of its own, so two at once cannot be confused")

		-- The pod's BASE, not its middle: a creature is built from its base, and a
		-- pivot would float every revealed plant by half an egg. Pod 2 is still in
		-- the bed, so its own floor is what the hatched pod's floor should match.
		local neighbour = modelFor(2)
		local box, size = neighbour:GetBoundingBox()
		local floor = box.Position.Y - size.Y * 0.5
		check(payload ~= nil and math.abs(payload.cf.Position.Y - floor) < 0.6,
			"the CFrame is the soil the shell sat on, not the shell's centre",
			string.format("%.2f vs a neighbour's floor at %.2f",
				if payload then payload.cf.Position.Y else -1, floor))
	end

	--==========================================================================
	-- 4. A SECOND HATCH, AND THE THINGS THAT DO NOT HATCH
	--==========================================================================
	say("\n-- once each, and never for a stranger --")
	do
		trace = {}
		--======================================================================
		-- NO SECOND PRESS: ONE DIALOG PER SECOND, BY DESIGN
		--
		-- OfferInstantHatch rate-limits a player to one purchase dialog a second,
		-- so this drives the OTHER documented door instead: a receipt with no note
		-- against it, which Roblox re-delivers after a rejoin. It takes the pod
		-- with the longest wait left, which is pod 3 -- the Dunebud fifteen
		-- minutes out -- and not pod 2, which is fifty seconds out.
		--======================================================================
		check(PlantService.InstantHatch(owner),
			"a receipt with no note hatches the pod with the longest wait left")
		local payload = reveals[#reveals]
		check(payload.discovery == false,
			"the second Dunebud is not a discovery", payload.discovery)
		check(payload.species == "dunebud" and payload.tier == 1
				and payload.token ~= reveals[1].token,
			"the fallback picked pod 3, and it is its own reveal with its own token",
			string.format("%s T%s", tostring(payload.species), tostring(payload.tier)))
		check(count("Reveal") == 1, "still one announcement per hatch", count("Reveal"))

		trace = {}
		check(PlantService.OfferInstantHatch(stranger, plotModel, 2) == false,
			"a stranger cannot even open the dialog for somebody else's pod")
		check(PlantService.InstantHatch(stranger) == false,
			"and a receipt in a stranger's name hatches nothing")
		check(count("Reveal") == 0, "so no reveal is announced", count("Reveal"))
		check(count("GiveHatched") == 0, "and nobody is handed a plant")

		trace = {}
		giveWorks = false
		check(PlantService.InstantHatch(owner) == false,
			"a hatch whose Tool cannot be created fails")
		check(count("Reveal") == 0,
			"and announces nothing, because nothing happened", count("Reveal"))
		check(count("SetPlants") == 0, "and saves nothing")
		giveWorks = true
	end

	--==========================================================================
	-- 5. ONE HATCH, TWO DOORS
	--==========================================================================
	say("\n-- the free path is the same path --")
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
		-- PLAIN FINDS, not patterns: a Luau string full of dots and brackets is a
		-- pattern that matches nothing, and a source check that always passes is
		-- worse than no source check.
		local plant = sourceOf(Server:FindFirstChild("PlantService"))
		check(plant ~= nil and plant:find("prompt.Triggered:Connect(function(player)", 1, true)
				and plant:find("hatch(player, entry)", 1, true),
			"the free prompt calls the same hatch()")
		check(plant ~= nil and select(2, plant:gsub("announceReveal%(%{", "")) == 1,
			"which announces the reveal in exactly one place, for both doors",
			plant and select(2, plant:gsub("announceReveal%(%{", "")))

		local scripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
		local cues = sourceOf(scripts and scripts:FindFirstChild("SoundCues"))
		check(cues ~= nil and not cues:find("PromptTriggered", 1, true)
				and not cues:find("revealUntil", 1, true),
			"SoundCues no longer arms anything off a held prompt")
		check(cues ~= nil and not cues:find("RevealFor", 1, true),
			"and does not play the reveal at all any more")
		local fx = sourceOf(scripts and scripts:FindFirstChild("HatchFX"))
		check(fx ~= nil, "HatchFX exists on the client")
		check(fx ~= nil and fx:find("RevealFor", 1, true) and fx:find("HATCH.Action", 1, true),
			"and plays the rarity fanfare off the authoritative event")
		check(fx ~= nil and fx:find("SeedAfterimageQuality", 1, true),
			"it honours Reduced Effects")
		check(fx ~= nil and not fx:find("CameraType", 1, true)
				and not fx:find("Scriptable", 1, true),
			"and never takes the camera")
	end
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

if plotModel then
	plotModel:Destroy()
end

say(string.format("\nHatchRevealSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
