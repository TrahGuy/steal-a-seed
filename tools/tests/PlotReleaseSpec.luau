--!nocheck
--==============================================================================
-- Steal a Seed :: PlotReleaseSpec
--
-- A plot changes hands without anybody's garden going with it, or being lost.
-- Reported 2026-09-26 as "when you left the game your base wasn't reset". Edit
-- mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PlotReleaseSpec"))
--
--   1. The REAL PlantService, fresh-loaded against stand-ins (the
--      PlantStreamingSpec set), driven through a slow profile load, a release,
--      a second owner, the first owner coming back on another plot, and an old
--      owner's late restore landing after the plot has changed hands. What is
--      counted is what reaches SetPlants -- the profile write -- and what
--      stands in each plot's Plants folder.
--   2. The nameplate over the gate: what it says, to whom, and that it reads
--      PlotService's OwnerUserId and nothing else.
--   3. The rest of the leave path, from source: the mill goes back to the
--      starting tier on release, and a rejoin waits for this server's leave
--      save instead of racing it.
--
-- Not here, verified in Play instead: two real clients watching one plot
-- change hands, a real DataStore, and the mill rebuild itself.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
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

local function sourceOf(instance)
	if not instance then
		return ""
	end
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok and type(src) == "string" then src else ""
end

--==============================================================================
-- THE STAND-INS
--==============================================================================
local fakePlayers = {}
fakePlayers.PlayerRemoving = {
	Connect = function()
		return { Disconnect = function() end }
	end,
}
local ownerA = { Name = "SpecOwnerA", UserId = 9101, Parent = fakePlayers }
local ownerB = { Name = "SpecOwnerB", UserId = 9102, Parent = fakePlayers }
-- A rejoin is a NEW Player object for the same account.
local ownerA2 = { Name = "SpecOwnerA", UserId = 9101, Parent = fakePlayers }

local leases = {} -- player -> plot
local holder = {} -- plot -> player
local ready = {} -- player -> bool
local profiles = {} -- player -> profile
local writes = {} -- { player, count }
local assignedFn, releasedFn = nil, nil

local PlotService = {
	OwnerOf = function(plot)
		return holder[plot]
	end,
	PlotOf = function(player)
		return leases[player]
	end,
	OnAssigned = function(fn)
		assignedFn = fn
	end,
	OnReleased = function(fn)
		releasedFn = fn
	end,
	OnResizing = function() end,
	OnResized = function() end,
}

local PlayerDataService = {
	IsReady = function(player)
		return ready[player] == true
	end,
	Get = function(player)
		return if ready[player] then profiles[player] else nil
	end,
	SetPlants = function(player, list)
		table.insert(writes, { player = player, count = #list })
		if profiles[player] then
			profiles[player].Plants = list
		end
	end,
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

local function makePlot(name, id, y)
	local plot = Instance.new("Model")
	plot.Name = name
	plot.Archivable = false
	plot:SetAttribute("PreviewOnly", true)
	plot:SetAttribute(GameConfig.Attributes.PlotId, id)
	plot.Parent = workspace
	local depth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + depth * 0.5
	plot:SetAttribute("PlotCF", CFrame.lookAt(Vector3.new(0, y, centreR), Vector3.new(0, y, 0)))
	plot:SetAttribute("Depth", depth)
	MapService.ResizePlot(plot, 1)
	return plot
end

local function plantsIn(plot)
	local folder = plot:FindFirstChild(GameConfig.Plot.PlantsFolderName)
	local n = 0
	for _, m in ipairs(folder and folder:GetChildren() or {}) do
		if m:IsA("Model") then
			n += 1
		end
	end
	return n
end

local function writesFor(player)
	local n, last = 0, nil
	for _, w in ipairs(writes) do
		if w.player == player then
			n += 1
			last = w.count
		end
	end
	return n, last
end

-- PlotService's own order: listeners, then the clear, then the plot is free.
local function release(player, plot)
	leases[player] = nil
	holder[plot] = nil
	if releasedFn then
		releasedFn(player, plot)
	end
	local folder = plot:FindFirstChild(GameConfig.Plot.PlantsFolderName)
	if folder then
		folder:ClearAllChildren()
	end
end

local function assign(player, plot)
	leases[player] = plot
	holder[plot] = player
	assignedFn(player, plot)
end

local function waitFor(test, seconds)
	local deadline = os.clock() + (seconds or 3)
	while not test() and os.clock() < deadline do
		task.wait(0.05)
	end
	return test()
end

--==============================================================================
-- BODY
--==============================================================================
local PlantService = nil
local plotOne, plotTwo = nil, nil

local function garden()
	say("\n-- a plot changes hands; no garden goes with it, none is lost --")
	local now = os.time()
	profiles[ownerA] = { Plants = {
		{ SpeciesId = "petalpip", Tier = 1, PlantedAt = now - 60, HatchAt = now - 60,
			X = -8, Z = -4, Stage = 3, Facing = 0 },
		{ SpeciesId = "nubkin", Tier = 3, PlantedAt = now, HatchAt = now + 900,
			X = 0, Z = 6, Stage = 1, Facing = 0 },
	} }
	profiles[ownerB] = { Plants = {} }
	plotOne = makePlot("PlotReleaseSpecOne", 96, 960)
	plotTwo = makePlot("PlotReleaseSpecTwo", 97, 1000)

	local loadOk, loadErr = pcall(function()
		PlantService = loadWith(Server.PlantService, {
			PlotService = PlotService,
			PlayerDataService = PlayerDataService,
			CarryService = CarryService,
			PlantWander = PlantWander,
			-- The saved garden's frame (2026-10-07): pure, so the real one.
			GardenFrame = require(Server:WaitForChild("GardenFrame")),
			-- The Mysterious Pod (2026-10-11): no shells in this fixture.
			MysteryPodService = { IsShell = function() return false end, Outcome = function() return nil end,
				Consume = function() end, TellHatch = function() end },
		})
		PlantService.Init()
		PlantService.Start()
	end)
	check(loadOk and assignedFn ~= nil and releasedFn ~= nil,
		"PlantService loads, starts, and listens for assignment and release", loadErr)
	if not (loadOk and assignedFn and releasedFn) then
		return
	end

	--== A SLOW LOAD: THE BED STAYS SHUT ==--
	assign(ownerA, plotOne)
	task.wait(0.4)
	local placed, code = PlantService.PlaceAt(ownerA, Vector3.new(0, 960, 0))
	check(not placed and code == "NO_PROFILE",
		"while A's save is still loading, planting is refused", tostring(code))
	check(not PlantService.GardenRestored(plotOne) and writesFor(ownerA) == 0,
		"and nothing is written to A's profile -- the bed is not an empty garden, it has not arrived",
		writesFor(ownerA))
	ready[ownerA] = true
	check(waitFor(function()
		return PlantService.GardenRestored(plotOne)
	end), "when the save lands, restore puts A's garden back and the bed opens")
	local nA, lastA = writesFor(ownerA)
	check(plantsIn(plotOne) == 2 and nA == 1 and lastA == 2,
		"A's two plants stand in the plot, and the one write carries both of them",
		string.format("%d standing, %d write(s), last %s", plantsIn(plotOne), nA, tostring(lastA)))

	--== A LEAVES ==--
	local before = #writes
	release(ownerA, plotOne)
	check(not PlantService.GardenRestored(plotOne), "released, the plot's bed shuts")
	check(plantsIn(plotOne) == 0, "and its plants are gone", plantsIn(plotOne))
	check(#writes == before and #profiles[ownerA].Plants == 2,
		"and the release wrote nothing: A's saved garden is still two plants",
		string.format("%d new write(s), %d saved", #writes - before, #profiles[ownerA].Plants))
	release(ownerA, plotOne)
	check(#writes == before and plantsIn(plotOne) == 0, "releasing twice changes nothing")

	--== B TAKES THE PLOT ==--
	ready[ownerB] = true
	assign(ownerB, plotOne)
	check(waitFor(function()
		return PlantService.GardenRestored(plotOne)
	end), "B is given the same plot and their own (empty) garden opens it")
	check(plantsIn(plotOne) == 0, "B inherits none of A's plants", plantsIn(plotOne))
	local placedA, codeA = PlantService.PlaceAt(ownerA, Vector3.new(0, 960, 0))
	check(not placedA and (codeA == "NO_PLOT" or codeA == "NO_PROFILE"),
		"and A has no say in it any more", tostring(codeA))
	check(#profiles[ownerA].Plants == 2, "A's save is untouched by B's arrival",
		#profiles[ownerA].Plants)

	--== A COMES BACK, ON ANOTHER PLOT ==--
	profiles[ownerA2] = profiles[ownerA]
	ready[ownerA2] = true
	assign(ownerA2, plotTwo)
	check(waitFor(function()
		return PlantService.GardenRestored(plotTwo) and plantsIn(plotTwo) == 2
	end), "A rejoins onto a free plot and both saved plants come back",
		plantsIn(plotTwo))
	check(plantsIn(plotOne) == 0 and PlantService.GardenRestored(plotOne),
		"while B's plot is left exactly as it was")

	--== AN OLD OWNER'S LATE RESTORE ==--
	-- C is assigned, leaves before their save lands, and B2 takes the plot. When
	-- C's save finally arrives, their waiting restore must not touch it.
	local ownerC = { Name = "SpecOwnerC", UserId = 9103, Parent = fakePlayers }
	local ownerB2 = { Name = "SpecOwnerB2", UserId = 9104, Parent = fakePlayers }
	profiles[ownerC] = { Plants = { { SpeciesId = "petalpip", Tier = 1, PlantedAt = now - 60,
		HatchAt = now - 60, X = 4, Z = 4, Stage = 3, Facing = 0 } } }
	profiles[ownerB2] = { Plants = {} }
	release(ownerB, plotOne)
	assign(ownerC, plotOne)
	task.wait(0.3)
	release(ownerC, plotOne)
	ready[ownerB2] = true
	assign(ownerB2, plotOne)
	check(waitFor(function()
		return PlantService.GardenRestored(plotOne)
	end), "B2 is given the plot C left before C's save arrived")
	ready[ownerC] = true
	task.wait(0.6)
	check(plantsIn(plotOne) == 0 and PlantService.GardenRestored(plotOne)
			and writesFor(ownerC) == 0,
		"C's save landing late restores nothing into B2's plot and writes nothing",
		string.format("%d standing, %d write(s) for C", plantsIn(plotOne), writesFor(ownerC)))
end

local function nameplate()
	say("\n-- the owner's badge over the gate, and the plaque outside it --")
	local me = 5000
	local k, n = GameConfig.plotBadgeFor(0, me, nil)
	check(k == "free" and n == "", "a free plot: no badge, no name", k)
	k, n = GameConfig.plotBadgeFor(nil, me, "someone")
	check(k == "free" and n == "", "no owner attribute at all: free too", k)
	k, n = GameConfig.plotBadgeFor(me, me, "bacon_123")
	check(k == "mine" and n == "bacon_123",
		"the viewer's own plot: the accent badge, with their USERNAME under it", k .. " / " .. n)
	k, n = GameConfig.plotBadgeFor(42, me, "mike_42")
	check(k == "theirs" and n == "mike_42", "somebody else's: their username", k .. " / " .. n)
	k, n = GameConfig.plotBadgeFor(42, me, nil)
	check(k == "theirs" and n == "", "before any name has replicated: the badge, blank underneath", k)
	check(GameConfig.avatarHeadshot(42) == "rbxthumb://type=AvatarHeadShot&id=42&w=150&h=150",
		"the face is the owner's headshot, by id", GameConfig.avatarHeadshot(42))

	local a, b, c, d = GameConfig.plotStatsText(nil, 2, 10, 100, nil)
	check(a == nil and b == nil and c == nil and d == nil,
		"no published numbers: the plaque has nothing to say (never 0/10)")
	a, b, c, d = GameConfig.plotStatsText(6, 2, 10, 15992, 2)
	check(a == "PLANTS 8/10" and b == "2 hatching" and c == "$" .. GameConfig.compact(15992) .. "/s"
			and d == "with x2 boost",
		"grown and hatching count against capacity; the income carries its boost", string.format(
			"%s | %s | %s | %s", tostring(a), tostring(b), tostring(c), tostring(d)))
	a, b, c, d = GameConfig.plotStatsText(3, 0, 5, 40, nil)
	check(a == "PLANTS 3/5" and b == "" and d == "", "nothing hatching and no boost: those lines stay empty")

	local B = GameConfig.Plot.OwnerBadge
	check(B.HeightStuds - B.TallStuds * 0.5 > 5.8 + 7,
		"the badge floats well clear of the gateposts, a jump and the way in",
		B.HeightStuds - B.TallStuds * 0.5)
	check(B.NearStuds > 0 and B.FarStuds > B.NearStuds and B.MaxDistance > B.FarStuds,
		"its apparent size is clamped between two distances and it hides beyond a third")
	local S = GameConfig.Plot.StatsSign
	check(math.abs(S.OffsetX) - S.BoardSize.X * 0.5 > GameConfig.Plot.GateWidth * 0.5,
		"the plaque stands clear of the gate opening", math.abs(S.OffsetX) - S.BoardSize.X * 0.5)

	local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	local src = sourceOf(scripts and scripts:FindFirstChild("PlotOwnerLabels"))
	check(src ~= "", "PlotOwnerLabels is in StarterPlayerScripts")
	check(string.find(src, "plot:GetAttribute(ATTR.OwnerUserId)", 1, true) ~= nil
			and string.find(src, "GameConfig.plotBadgeFor(ownerId, player.UserId, username)", 1, true) ~= nil,
		"it reads PlotService's OwnerUserId and shows what plotBadgeFor says")
	check(string.find(src, "plot:GetAttributeChangedSignal(attr):Connect(function()\n\t\t\tpaint(plot, plate)", 1, true) ~= nil
			and string.find(src, "ATTR.OwnerUserId, ATTR.OwnerName, ATTR.Claimed", 1, true) ~= nil,
		"and repaints on assignment, release and reassignment -- every change of the owner attributes")
	check(string.find(src, "if plate.token ~= token then", 1, true) ~= nil
			and string.find(src, "plate.face.Image = GameConfig.avatarHeadshot(ownerId)", 1, true) ~= nil,
		"a headshot load that finishes after the plot changed hands does nothing")
	check(string.find(src, "return distance / math.clamp(distance, BADGE.NearStuds, BADGE.FarStuds)", 1, true) ~= nil
			and string.find(src, "if math.abs(f - plate.badgeFactor) > 0.004 then", 1, true) ~= nil
			and select(2, string.gsub(src, "BindToRenderStep", "")) == 1,
		"the size clamp: one cheap pass after the camera, writing Size only when the factor moves")
	check(string.find(src, "board.AlwaysOnTop = false", 1, true) ~= nil
			and string.find(src, "board.Active = false", 1, true) ~= nil
			and string.find(src, "p.CanCollide = false", 1, true) ~= nil
			and string.find(src, "p.CanQuery = false", 1, true) ~= nil
			and not string.find(src, "Selectable = true", 1, true)
			and not string.find(src, "RemoteEvent", 1, true)
			and not string.find(src, "Heartbeat", 1, true)
			and not string.find(src, "RenderStepped", 1, true),
		"behind the world, never a pad stop, cannot catch a runner or a click, no remote, no other per-frame work")
	check(not string.find(src, '"YOUR BASE"', 1, true) and not string.find(src, '"OwnerPlate"', 1, true)
			and not string.find(src, "plotLabelText", 1, true),
		"the old plate is gone, not left beside the badge")
end

local function leavePath()
	say("\n-- the rest of the leave path --")
	local mill = sourceOf(Server:FindFirstChild("TreadmillService"))
	check(string.find(mill, "releaseHook = PlotService.OnReleased(function(player, plot)", 1, true) ~= nil
			and string.find(mill, "TreadmillService.Rebuild(plot, LADDER.StartingTier)", 1, true) ~= nil
			and string.find(mill, "setBeltSpeed(belt, false, LADDER.StartingTier)", 1, true) ~= nil,
		"a released plot's mill goes back to the starting tier, belt idle")
	check(string.find(mill, 'mill:GetAttribute("MillTier") ~= LADDER.StartingTier', 1, true) ~= nil,
		"and a new owner's mill is rebuilt from what is standing there, not only from their tier")
	local plant = sourceOf(Server:FindFirstChild("PlantService"))
	check(string.find(plant, "if owner and restoredFor[plot] == owner then", 1, true) ~= nil
			and string.find(plant, "GameConfig.Plot.RestorePatienceSeconds", 1, true) ~= nil
			and not string.find(plant, "os.clock() + 30\n", 1, true),
		"PlantService saves a bed only once its garden is back, and waits for as long as the player stays")
	local data = sourceOf(Server:FindFirstChild("PlayerDataService"))
	check(string.find(data, "while leavingSaves[player.UserId] and player.Parent == Players", 1, true) ~= nil
			and string.find(data, "and not entry.leaving", 1, true) ~= nil,
		"a rejoin to this server waits for its own leave save, and the autosave keeps off a leaving entry")
	-- Reproduced in Play 2026-09-26 on a throwaway profile: an autosave in flight at the leave
	-- committed AFTER the releasing save and left the record locked. One write per player at a
	-- time, the next waiting for the last, so the release is always the last word.
	local writeFn = string.match(data, "local function write%(.-\nend") or ""
	check(string.find(writeFn, "while writing[userId] and os.clock() < waitUntil do", 1, true) ~= nil
			and string.find(writeFn, "local called, saved = pcall(SaveService.Save, userId, entry.profile, release)", 1, true) ~= nil
			and string.find(writeFn, "writing[userId] = nil", 1, true) ~= nil,
		"a save waits for the player's save already in flight, so the leave's release lands last")
	check(GameConfig.Plot.RestorePatienceSeconds >= 60,
		"the restore backstop is minutes, not the 30 s a slow save outlasted",
		GameConfig.Plot.RestorePatienceSeconds)
end

local ok, err = pcall(function()
	garden()
	nameplate()
	leavePath()
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
if PlantService then
	pcall(PlantService.Init)
end
for _, plot in ipairs({ plotOne, plotTwo }) do
	if plot then
		plot:Destroy()
	end
end
say(string.format("\nPlotReleaseSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
