--!nocheck
--==============================================================================
-- Steal a Seed :: PlantStreamingSpec
--
-- A planted creature arrives and leaves WHOLE, and PlantSway animates it from
-- its authored rest pose however often it is registered. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PlantStreamingSpec"))
--
-- THE DEFECT (KB/HANDOFF, 2026-09-23). The engine streamed a garden part by
-- part. The server never moves a planted creature's parts, so every part that
-- came back arrived where the plant was BUILT, while PlantSway had walked it
-- somewhere else and moves it with a relative PivotTo -- and the part stayed 4
-- to 65 studs off its plant for the rest of the session. A fresh copy of
-- PlantSway did a smaller version of the same thing to legs and roots: it took
-- the pose the last copy left behind as its idea of rest.
--
--   1. PlantService, fresh-loaded against stand-ins, restores a garden of
--      grown creatures and pods. Every model it builds streams as a unit.
--   2. PlantSway's rest record, extracted from its Source and RUN on real
--      CreatureModel builds at Tiny, Mega and Colossal: every part is posed
--      the way a walk, a blink and a gaze pose it, the plant is re-registered,
--      and it must come back to the authored pose exactly -- five times over,
--      and when its Base comes back at the server's pose while the rest of it
--      stayed where the client last drew it.
--
-- Not here, verified in Play instead: the engine's streaming itself (a run to
-- Starbloom and back), the owner half of PersistentPerPlayer (it needs a real
-- Player), PlantSway's walk, and two clients watching one garden.
--==============================================================================

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

--==============================================================================
-- THE STAND-INS (the HatchRevealSpec set, trimmed to what a restore touches)
--==============================================================================
local fakePlayers = {}
fakePlayers.PlayerRemoving = {
	Connect = function()
		return { Disconnect = function() end }
	end,
}
local owner = { Name = "SpecOwner", UserId = 8282, Parent = fakePlayers }

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
	Get = function(playerArg)
		return if playerArg == owner then profile else nil
	end,
	SetPlants = function() end,
	MarkSeen = function()
		return false
	end,
	RecordTutorial = function() end,
}

local CarryService = {
	GiveHatched = function()
		return true
	end,
	SyncHeldNow = function() end,
}

local fakeMarket = {}
function fakeMarket:PromptProductPurchase() end

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "MarketplaceService" then
		return fakeMarket
	elseif name == "Players" then
		return fakePlayers
	end
	return game:GetService(name)
end

local outerRequire = require
local function loadWith(module, siblings)
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
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) })
	setfenv(chunk, env)
	return chunk()
end

--==============================================================================
-- THE POSES PLANTSWAY DRAWS, AND THE COMPARISON
--==============================================================================
local LEG_WORDS = { "Thigh", "Femur", "Haunch", "Shin", "Tibia", "Knee", "Hock",
	"Foot", "Hoof", "Paw", "Toe", "Stilt", "Pillar" }

local function partsOf(model)
	local list = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

-- The walk, then the animated groups on top of it: a Leaf swung about its own
-- centre, a leg part swung about a hip over it, an eye slid across the face, a
-- lid dropped, an eye shrunk mid-blink. Deterministic, and bigger than the real
-- amplitudes so a partial restore cannot hide inside them.
local function poseLikeAWalk(model, target, cycle)
	model:PivotTo(target)
	for i, p in ipairs(partsOf(model)) do
		local n = p.Name
		local k = (i * 37 + cycle * 11) % 17 / 17 - 0.5
		if n == "Leaf" then
			p.CFrame = p.CFrame * CFrame.Angles(math.rad(40 * k), 0, 0)
		elseif n:sub(-3) == "Eye" or n:sub(-5) == "Pupil" or n:sub(-5) == "Glint" then
			p.CFrame = p.CFrame + p.CFrame.RightVector * (0.6 * k)
			p.Size = p.Size * 0.3
		elseif n:sub(-3) == "Lid" then
			p.CFrame = p.CFrame * CFrame.new(0, -0.8, 0)
		elseif string.match(n, "^Root%a*%d$") then
			p.CFrame = CFrame.new(p.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(math.rad(25 * k), 0, 0)
				* CFrame.new(0, -2, 0) * p.CFrame.Rotation
		else
			for _, w in ipairs(LEG_WORDS) do
				if string.find(n, w) then
					local hip = p.CFrame * CFrame.new(0, p.Size.Y * 0.5 + 1.5, 0)
					p.CFrame = hip * CFrame.Angles(math.rad(35 * k), 0, 0) * hip:ToObjectSpace(p.CFrame)
					break
				end
			end
		end
	end
end

-- Worst position gap, worst angle and worst size ratio between two builds, each
-- part measured from its own model's pivot. Builds are deterministic, so the two
-- part lists line up by index (PlantFormsSpec pins that).
local function compare(model, pristine)
	local a, b = partsOf(model), partsOf(pristine)
	if #a ~= #b then
		return math.huge, math.huge, 0, string.format("%d parts vs %d", #a, #b)
	end
	local ia, ib = model:GetPivot():Inverse(), pristine:GetPivot():Inverse()
	local gap, angle, sizeWorst, worstName = 0, 0, 1, ""
	for i = 1, #a do
		local ra, rb = ia * a[i].CFrame, ib * b[i].CFrame
		local g = (ra.Position - rb.Position).Magnitude
		-- The chord between matching axes, not ToAxisAngle: its acos turns float
		-- noise near identity into a steady 0.07 degrees on the replayed builds.
		local chord = math.max((ra.RightVector - rb.RightVector).Magnitude,
			(ra.UpVector - rb.UpVector).Magnitude, (ra.LookVector - rb.LookVector).Magnitude)
		local ratio = a[i].Size.Magnitude / b[i].Size.Magnitude
		if g > gap then
			gap, worstName = g, a[i].Name
		end
		angle = math.max(angle, math.deg(chord))
		sizeWorst = math.min(sizeWorst, ratio, 1 / ratio)
	end
	return gap, angle, sizeWorst, worstName
end

--==============================================================================
-- BODY
--==============================================================================
local stage = nil
local PlantService = nil

local function body()
	--==========================================================================
	-- 1. A PLANTED CREATURE STREAMS AS ONE THING
	--==========================================================================
	say("\n-- the garden streams whole --")
	plotModel = Instance.new("Model")
	plotModel.Name = "PlantStreamingSpecPlot"
	plotModel.Archivable = false
	plotModel:SetAttribute("PreviewOnly", true)
	plotModel:SetAttribute(GameConfig.Attributes.PlotId, 95)
	plotModel.Parent = workspace
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	plotModel:SetAttribute("PlotCF",
		CFrame.lookAt(Vector3.new(0, 940, centreR), Vector3.new(0, 940, 0)))
	plotModel:SetAttribute("Depth", startDepth)
	MapService.ResizePlot(plotModel, 1)

	local now = os.time()
	profile.Plants = {
		{ SpeciesId = "petalpip", Tier = 1, PlantedAt = now - 60, HatchAt = now - 60,
			X = -8, Z = -4, Stage = 3, Facing = 0 },
		{ SpeciesId = "toadcap", Tier = 6, PlantedAt = now - 60, HatchAt = now - 60,
			X = 6, Z = -2, Stage = 3, Facing = 1 },
		{ SpeciesId = "nubkin", Tier = 3, PlantedAt = now, HatchAt = now + 900,
			X = 0, Z = 6, Stage = 1, Facing = 0 },
	}

	local loadOk, loadErr = pcall(function()
		PlantService = loadWith(Server.PlantService, {
			PlotService = PlotService,
			PlayerDataService = PlayerDataService,
			CarryService = CarryService,
			PlantWander = PlantWander,
		})
		PlantService.Init()
		PlantService.Start()
	end)
	check(loadOk and assignedFn ~= nil, "PlantService loads and starts against the stand-ins", loadErr)
	if not (loadOk and assignedFn) then
		return
	end

	local restoreOk, restoreErr = pcall(assignedFn, owner, plotModel)
	check(restoreOk, "a garden restores for an owner that is not a real Player", restoreErr)

	local plants = plotModel:FindFirstChild(GameConfig.Plot.PlantsFolderName)
	local models = {}
	for _, m in ipairs(plants and plants:GetChildren() or {}) do
		if m:IsA("Model") then
			table.insert(models, m)
		end
	end
	check(#models == #profile.Plants, "one model per saved row", #models)
	local wholes, grown, pods, strangers = 0, 0, 0, 0
	for _, m in ipairs(models) do
		if m.ModelStreamingMode == Enum.ModelStreamingMode.PersistentPerPlayer then
			wholes += 1
		end
		if m:GetAttribute("Stage") == CreatureModel.STAGE_GROWN then
			grown += 1
		elseif m:GetAttribute("Stage") == CreatureModel.STAGE_POD then
			pods += 1
		end
		strangers += #m:GetPersistentPlayers()
	end
	check(wholes == #models,
		"every model streams as a unit: PersistentPerPlayer, Atomic for anyone not added",
		string.format("%d of %d", wholes, #models))
	check(grown == 2 and pods == 1, "grown creatures and pods alike go through that render",
		string.format("%d grown, %d pods", grown, pods))
	check(strangers == 0, "a stand-in owner is not made persistent (only a real Player can be)",
		strangers)

	--==========================================================================
	-- 2. PLANTSWAY'S REST RECORD, RUN
	--==========================================================================
	say("\n-- the rest pose survives re-registration --")
	local scripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local sway = scripts and scripts:FindFirstChild("PlantSway")
	local src = sway and sway.Source or ""
	-- PLAIN FINDS: the function is lifted out whole and compiled on its own.
	local from = src:find("local REST_OFFSET = ", 1, true)
	local to = from and src:find("local function remember", from, true)
	check(from ~= nil and to ~= nil, "PlantSway carries the rest record ahead of remember()")
	if not (from and to) then
		return
	end
	local chunk, chunkErr = loadstring(src:sub(from, to - 1) .. "\nreturn restoreRest", "=PlantSway.restoreRest")
	check(chunk ~= nil, "and it compiles on its own", chunkErr)
	if not chunk then
		return
	end
	local restoreRest = chunk()
	local buildAt = src:find("restoreRest(model)", 1, true)
	local measureAt = src:find("MEASURE THE THING", 1, true)
	check(buildAt ~= nil and measureAt ~= nil and buildAt < measureAt,
		"registration puts the plant back on its record BEFORE anything is measured")

	stage = Instance.new("Folder")
	stage.Name = "PlantStreamingSpecStage"
	stage.Archivable = false
	stage.Parent = workspace

	local CASES = {
		"nubkin", "petalpip", "spiretip", "toadcap", "bellchime", "dunebud", "astralhorn",
	}
	local S = CFrame.new(0, 960, 400) * CFrame.Angles(0, math.rad(35), 0)
	local walked = CFrame.new(23, 960, 441) * CFrame.Angles(0, math.rad(-80), 0)

	local worstCycle, worstB, worstName, worstAngle = 0, 0, "", 0
	local sizeCycle, sizeB = 1, 1
	local firstStamp, stampTotal = 0, 0
	local cycleFail, bFail = {}, {}
	for _, id in ipairs(CASES) do
		local sp = SeedData.Get(id)
		for _, tier in ipairs({ 1, 4, SeedData.TierCount }) do
			local pristine = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, S, stage)

			-- Registration one: the plant has just arrived, untouched.
			local plant = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, S, stage)
			restoreRest(plant)
			for _, p in ipairs(partsOf(plant)) do
				stampTotal += 1
				if typeof(p:GetAttribute("SwayRestOffset")) == "CFrame"
					and typeof(p:GetAttribute("SwayRestSize")) == "Vector3" then
					firstStamp += 1
				end
			end

			-- Five re-runs: walked, posed mid-stride, mid-blink, eyes aside, then
			-- registered again. Rest must not move by a hair.
			for cycle = 1, 5 do
				poseLikeAWalk(plant, walked * CFrame.new(cycle * 1.7, 0, 0), cycle)
				restoreRest(plant)
				local gap, angle, sizeRatio, name = compare(plant, pristine)
				if gap > 1e-3 or angle > 0.05 or sizeRatio < 0.999 then
					table.insert(cycleFail, string.format("%s T%d cycle %d: %.4f studs / %.3f deg / size x%.3f at %s",
						id, tier, cycle, gap, angle, sizeRatio, name))
				end
				if gap > worstCycle then
					worstCycle, worstName = gap, id .. " T" .. tier .. " " .. name
				end
				worstAngle = math.max(worstAngle, angle)
				sizeCycle = math.min(sizeCycle, sizeRatio)
			end

			-- The streaming shape: everything but the Base stayed where the client
			-- last drew it; the Base comes back at the server's pose.
			poseLikeAWalk(plant, walked, 9)
			plant.PrimaryPart.CFrame = pristine.PrimaryPart.CFrame
			restoreRest(plant)
			local worldGap = 0
			local a, b = partsOf(plant), partsOf(pristine)
			for i = 1, math.min(#a, #b) do
				worldGap = math.max(worldGap, (a[i].Position - b[i].Position).Magnitude)
			end
			local _, _, sizeRatio = compare(plant, pristine)
			sizeB = math.min(sizeB, sizeRatio)
			worstB = math.max(worstB, worldGap)
			if worldGap > 1e-3 or sizeRatio < 0.999 then
				table.insert(bFail, string.format("%s T%d: %.4f studs, size x%.3f", id, tier, worldGap, sizeRatio))
			end

			plant:Destroy()
			pristine:Destroy()
		end
	end
	check(firstStamp == stampTotal and stampTotal > 0,
		"the first registration writes a rest offset and size on every part",
		string.format("%d of %d", firstStamp, stampTotal))
	check(#cycleFail == 0,
		string.format("five pose-and-re-register cycles, 7 species x Tiny/Mega/Colossal: back to the authored pose (worst %.5f studs, %.4f deg, size x%.4f)",
			worstCycle, worstAngle, sizeCycle),
		table.concat(cycleFail, " | "))
	check(#bFail == 0,
		string.format("a Base that returns at the server's pose pulls every stayed part back onto it (worst %.5f studs, size x%.4f)",
			worstB, sizeB),
		table.concat(bFail, " | "))
	say(string.format("        (worst part over the cycles: %s)", worstName))
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

-- Stop the fresh PlantService's tick and take its models with it, then the stage.
if PlantService then
	pcall(PlantService.Init)
end
if plotModel then
	plotModel:Destroy()
end
if stage then
	stage:Destroy()
end

say(string.format("\nPlantStreamingSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
