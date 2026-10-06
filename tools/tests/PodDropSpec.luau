--!nocheck
--==============================================================================
-- Steal a Seed :: PodDropSpec (2026-10-04, the owner's combat brief)
--
-- Edit mode, no Play:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PodDropSpec"))
--
-- The REAL CarryService.DropHeldPod -- the one drop a bat and every trap now ask
-- for -- with the REAL PlayerDataService and ProfileSchema behind it, fresh-
-- required. The owner's report was a player hit while carrying a pod who kept
-- it; the cause was that hits asked IsCarrying (the RAID carry alone) while the
-- pod in the hands was a banked Tool.
--
-- Checked: a banked pod held as a Tool comes off as exactly ONE loose pod of the
-- same species and size, its saved row goes by its own Item id, the Tool goes,
-- and a second call drops nothing; a Secret pod and a Rain pod the same; a raid
-- carry (taken through the real TryTake) through Drop; and nothing else ever
-- comes off -- a pod still in the Backpack, a hatched plant in the hands, a
-- weapon. A respawn afterwards does not rebuild the dropped pod.
--
-- Stood in, as SacrificeSpec does: SaveService's Load and Save (in memory), the
-- plot, the garden and the pass. Players are stand-in tables with real signals,
-- a real Backpack and a real body over a ground part of the spec's own.
--
-- NOT here: the hit itself (BatHitSpec, TrapSystemSpec), the client.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local Server = ServerScriptService.SeedGameServer
local SaveService = require(Server.SaveService)
local PlotService = require(Server.PlotService)
local PlantService = require(Server.PlantService)
local ProfileSchema = require(Server.ProfileSchema)
local PlayerDataService = require(Server.PlayerDataService)
local CarryService = require(Server.CarryService)
local PassService = require(Server.PassService)
local Metrics = require(Server.Metrics)

local KG = GameConfig.Attributes.CarryingKg
local ITEM = GameConfig.Attributes.ItemId

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function section(title, fn)
	say("\n-- " .. title .. " --")
	local ran, why = pcall(fn)
	check(ran, title .. ": ran to its end", why)
end
local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

local fixture = Instance.new("Folder")
fixture.Name = "PodDropSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace

-- Somewhere far off the map, with a floor, so a dropped pod lands on the
-- spec's own ground. The pods themselves go into the map folder (that is where
-- DropHeldPod lays them), and are swept up by position at the end.
local HERE = Vector3.new(5200, 700, 5200)
local floor = Instance.new("Part")
floor.Name = "SpecFloor"
floor.Anchored = true
floor.Size = Vector3.new(120, 2, 120)
floor.Position = HERE - Vector3.new(0, 4, 0)
floor.Parent = fixture

local madeMap = nil
if not Workspace:FindFirstChild(GameConfig.Map.FolderName) then
	-- No map preview in this Edit session: a folder of that name, for the drop
	-- to lay its pod in, removed at the end.
	madeMap = Instance.new("Folder")
	madeMap.Name = GameConfig.Map.FolderName
	madeMap.Archivable = false
	madeMap.Parent = Workspace
end

local function podsHere(): { Model }
	local list = {}
	for _, pod in ipairs(CollectionService:GetTagged(GameConfig.Tags.SeedPod)) do
		if pod:IsA("Model") and pod.Parent then
			local pivot = pod:GetPivot().Position
			if (Vector3.new(pivot.X, 0, pivot.Z) - Vector3.new(HERE.X, 0, HERE.Z)).Magnitude < 40 then
				table.insert(list, pod)
			end
		end
	end
	return list
end
local function sweepPods()
	for _, pod in ipairs(podsHere()) do
		pod:Destroy()
	end
end

--==============================================================================
-- THE STAND-INS (SacrificeSpec's)
--==============================================================================
local saves, plots, plants, data, carry, passes, metrics = SaveService :: any, PlotService :: any,
	PlantService :: any, PlayerDataService :: any, CarryService :: any, PassService :: any, Metrics :: any
local store = {}
saves.Load = function(userId)
	assert(store[userId] ~= nil, "PodDropSpec joined a stand-in with no seeded save")
	return "ok", deepCopy(store[userId])
end
saves.Save = function(userId, payload)
	store[userId] = deepCopy(payload)
	return true
end
saves.Forget = function() end
plots.PlotOf = function()
	return nil
end
plots.OwnerOf = function()
	return nil
end
plots.SetDesiredLevel = function()
	return true
end
plants.GrownIn = function()
	return {}
end
plants.GardenRestored = function()
	return true
end
plants.CountIn = function()
	return 0
end
passes.CashMultiplier = function()
	return 1
end
local holders = {}
local realMount = data.MountStats
data.MountStats = function(holder, profile)
	return realMount(holders[holder] or holder, profile)
end
data.RecordTutorial = function() end
metrics.income = function() end
metrics.raidStarted = function() end
metrics.raidEnded = function() end

local function standIn(name, userId)
	local holder = Instance.new("Folder")
	holder.Name = name
	holder.Parent = fixture
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
		_holder = holder,
	}
	function p.SetAttribute(_, k, v)
		attrs[k] = v
	end
	function p.GetAttribute(_, k)
		return attrs[k]
	end
	function p.Kick() end
	function p.FindFirstChildOfClass(self, className)
		local backpack = self._backpack
		if className == "Backpack" and backpack and backpack.Parent then
			return backpack
		end
		return nil
	end
	function p.WaitForChild(_, childName)
		return holder:FindFirstChild(childName)
	end
	holders[p] = holder
	return p
end

local function newBody(p)
	local body = Instance.new("Model")
	body.Name = p.Name .. "Body"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = CFrame.new(HERE)
	root.Parent = body
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.CanCollide = false
	head.Size = Vector3.new(1, 1, 1)
	head.CFrame = CFrame.new(HERE + Vector3.new(0, 1.5, 0))
	head.Parent = body
	body.PrimaryPart = root
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = body
	body.Parent = p._holder
	p.Character = body
	p._body = body
	return body
end

local function enter(name, userId, bag)
	local raw = ProfileSchema.Sanitise(nil)
	raw.Held = deepCopy(bag)
	store[userId] = deepCopy(raw)
	local p = standIn(name, userId)
	data.Join(p)
	local backpack = Instance.new("Backpack")
	backpack.Parent = p._holder
	p._backpack = backpack
	newBody(p)
	carry.WatchHeld(p)
	carry.RestoreHeld(p)
	task.wait(0.3)
	for _, tool in ipairs(p._body:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Parent = backpack
		end
	end
	task.wait()
	return p
end

local function plantTools(p)
	local list = {}
	for _, container in ipairs({ p._backpack, p._body }) do
		if container and container.Parent then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and type(tool:GetAttribute("SpeciesId")) == "string" then
					table.insert(list, tool)
				end
			end
		end
	end
	return list
end

local function rows(p)
	local profile = data.Get(p)
	return if profile then profile.Held else {}
end

local function hasRow(p, item)
	for _, row in ipairs(rows(p)) do
		if row.Item == item then
			return true
		end
	end
	return false
end

-- One of this kind out of the bag and into the hands.
local function hold(p, id, hatched)
	for _, tool in ipairs(p._body:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Parent = p._backpack
		end
	end
	for _, tool in ipairs(p._backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("SpeciesId") == id
			and (tool:GetAttribute("Hatched") == true) == (hatched == true) then
			tool.Parent = p._body
			task.wait()
			return tool
		end
	end
	error(string.format("%s has no %s (hatched %s) in the bag", p.Name, id, tostring(hatched)))
end

local BAG = {
	{ Id = "nubkin", Tier = 3, Hatched = false },
	{ Id = "petalpip", Tier = 2, Hatched = false },
	{ Id = "snarlbloom", Tier = 1, Hatched = false },
	{ Id = "tempestoak", Tier = 1, Hatched = false },
	{ Id = "spiretip", Tier = 2, Hatched = true },
}

local ok, err = pcall(function()
	local p = enter("SpecDrop", -7301, BAG)
	section("the bag is in", function()
		check(carry.IsHeldRestored(p) and #plantTools(p) == #BAG and #rows(p) == #BAG,
			"five rows saved, five Tools rebuilt", string.format("%d tools, %d rows", #plantTools(p), #rows(p)))
		sweepPods()
	end)

	section("a banked pod held in the hands", function()
		local tool = hold(p, "nubkin", false)
		local item = tool:GetAttribute(ITEM)
		local tier = tool:GetAttribute(KG)
		check(type(item) == "string" and hasRow(p, item), "it is on the record by its own Item id", item)
		check(carry.HoldsPod(p) and not carry.IsCarrying(p),
			"HoldsPod sees it, where IsCarrying (the raid carry alone) does not -- the reported bug")
		local at = HERE + Vector3.new(0, 0, -1)
		local dropped, kind = carry.DropHeldPod(p, at)
		check(dropped == true and kind == "tool", "it comes off as a banked Tool", tostring(kind))
		check(tool.Parent == nil and not hasRow(p, item) and #rows(p) == #BAG - 1,
			"the Tool is gone and so is ITS row, by name -- one row, no other",
			string.format("%d rows", #rows(p)))
		local pods = podsHere()
		check(#pods == 1 and pods[1]:GetAttribute("SpeciesId") == "nubkin" and pods[1]:GetAttribute("Tier") == tier,
			"exactly ONE loose pod lies at their feet, the same species and the same size",
			#pods .. " pods")
		check(not carry.HoldsPod(p), "and the hands are empty")
		local again, kindAgain = carry.DropHeldPod(p, at)
		check(again == false and kindAgain == nil and #podsHere() == 1 and #rows(p) == #BAG - 1,
			"a second drop in the same moment drops nothing: no second pod, no second row lost")
		sweepPods()
	end)

	section("a Secret pod and a Rain pod", function()
		for _, id in ipairs({ "snarlbloom", "tempestoak" }) do
			local before = #rows(p)
			local tool = hold(p, id, false)
			local dropped, kind = carry.DropHeldPod(p, HERE)
			local pods = podsHere()
			check(dropped == true and kind == "tool" and tool.Parent == nil and #rows(p) == before - 1
					and #pods == 1 and pods[1]:GetAttribute("SpeciesId") == id,
				string.format("a held %s pod comes off as one loose %s pod", id, id), #pods .. " pods")
			sweepPods()
		end
	end)

	section("nothing else comes off", function()
		local before = #rows(p)
		-- Empty hands, pods in the bag.
		for _, tool in ipairs(p._body:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = p._backpack
			end
		end
		local d1 = carry.DropHeldPod(p, HERE)
		-- A hatched plant in the hands.
		local plant = hold(p, "spiretip", true)
		local d2 = carry.DropHeldPod(p, HERE)
		local plantStays = plant.Parent == p._body
		plant.Parent = p._backpack
		-- A weapon in the hands.
		local bat = Instance.new("Tool")
		bat.Name = "Rootwood Bat"
		bat:SetAttribute("WeaponItem", "rootwood_bat")
		bat.Parent = p._body
		local d3 = carry.DropHeldPod(p, HERE)
		bat:Destroy()
		check(d1 == false and d2 == false and d3 == false and plantStays and #rows(p) == before
				and #podsHere() == 0,
			"empty hands with pods in the bag, a HATCHED plant in the hands, a weapon: nothing is dropped")
	end)

	section("a respawn does not bring a dropped pod back", function()
		local before = #rows(p)
		local tool = hold(p, "petalpip", false)
		carry.DropHeldPod(p, HERE)
		sweepPods()
		check(#rows(p) == before - 1, "dropped")
		-- A new body and the record rebuilt onto it.
		p._body:Destroy()
		newBody(p)
		carry.RestoreHeld(p)
		task.wait(0.3)
		local petalpips = 0
		for _, t in ipairs(plantTools(p)) do
			if t:GetAttribute("SpeciesId") == "petalpip" then
				petalpips += 1
			end
		end
		check(petalpips == 0 and #plantTools(p) == #rows(p),
			"the rebuilt bag has no petalpip and matches the record", string.format("%d tools / %d rows",
				#plantTools(p), #rows(p)))
		check(tool.Parent == nil, "(the old Tool stays gone)")
	end)

	section("a raid carry", function()
		for _, t in ipairs(p._body:GetChildren()) do
			if t:IsA("Tool") then
				t.Parent = p._backpack
			end
		end
		local loose = carry.SpawnLoose("nubkin", 4, CFrame.new(HERE + Vector3.new(0, -2.9, -3)))
		check(loose ~= nil, "a loose pod lies on the road beside them")
		local took = loose and carry.TryTake(p, loose)
		check(took == true and carry.IsCarrying(p) and carry.HoldsPod(p), "and is taken: a raid carry",
			tostring(took))
		if took then
			local rowsBefore = #rows(p)
			local dropped, kind = carry.DropHeldPod(p, HERE)
			local pods = podsHere()
			check(dropped == true and kind == "carry" and not carry.IsCarrying(p) and #pods == 1
					and pods[1]:GetAttribute("SpeciesId") == "nubkin" and pods[1]:GetAttribute("Tier") == 4
					and #rows(p) == rowsBefore,
				"it comes off through Drop: one loose pod, same species and size, the record untouched",
				#pods .. " pods")
			check(carry.DropHeldPod(p, HERE) == false and #podsHere() == 1,
				"and a second drop finds nothing")
		end
		sweepPods()
	end)
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

sweepPods()
if madeMap then
	madeMap:Destroy()
end
fixture:Destroy()
say(string.format("\nPodDropSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
