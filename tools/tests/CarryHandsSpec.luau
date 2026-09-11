--!strict
--==============================================================================
-- Steal a Seed :: CarryHandsSpec
--
-- Taking a pod while holding a plant drew both: the raid pod in both arms and
-- the plant through it. Only the pod may be in the hands while it is carried.
-- Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("CarryHandsSpec"))
--
-- The real CarryService, fresh-required: the real TryTake, Drop and SpawnLoose,
-- and the real per-body watchers through CarryService.WatchBody. A stand-in
-- player carries a real Backpack and a real body with a Humanoid, on a floor in
-- a throwaway folder well away from the map.
--
-- Not here, verified in Play instead: the hotbar's own refusal in LoadoutUI and
-- what other players see.
--==============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Shared = game.ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local Server = game:GetService("ServerScriptService").SeedGameServer
local CarryService = require(Server.CarryService)

local pass = 0
local fails: { string } = {}
local function check(ok: boolean, label: string)
	if ok then
		pass += 1
	else
		table.insert(fails, label)
	end
end

local map = Workspace:FindFirstChild(GameConfig.Map.FolderName)
local ORIGIN = Vector3.new(40, 900, 40)

local fixture = Instance.new("Folder")
fixture.Name = "CarryHandsSpecFixture"
fixture.Parent = Workspace

local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Anchored = true
floor.Size = Vector3.new(60, 1, 60)
floor.CFrame = CFrame.new(ORIGIN - Vector3.new(0, 0.5, 0))
floor.Parent = fixture

local before: { [Instance]: boolean } = {}
if map then
	for _, d in ipairs(map:GetChildren()) do
		before[d] = true
	end
end

local function body(name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.CanCollide = false
	root.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 3, 0))
	root.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 4.5, 0))
	head.Parent = model
	Instance.new("Humanoid").Parent = model
	model.PrimaryPart = root
	model.Parent = fixture
	return model
end

local function stand(name: string, userId: number, character: Model): (any, Backpack)
	local backpack = Instance.new("Backpack")
	backpack.Parent = fixture
	local attrs: { [string]: any } = {}
	local p: any = {
		Name = name,
		UserId = userId,
		Parent = Players,
		Character = character,
	}
	function p.SetAttribute(_, k: string, v: any)
		attrs[k] = v
	end
	function p.GetAttribute(_, k: string): any
		return attrs[k]
	end
	function p.FindFirstChildOfClass(_, className: string): any
		if className == "Backpack" and backpack.Parent then
			return backpack
		end
		return nil
	end
	return p, backpack
end

local function tool(name: string, speciesId: string?): Tool
	local t = Instance.new("Tool")
	t.Name = name
	t.RequiresHandle = false
	if speciesId then
		t:SetAttribute("SpeciesId", speciesId)
		t:SetAttribute(GameConfig.Attributes.CarryingKg, 2)
		t:SetAttribute("Hatched", true)
	end
	return t
end

local function loosePod(): Model
	return CarryService.SpawnLoose("nubkin", 1, CFrame.new(ORIGIN + Vector3.new(0, 0, -2)), nil, nil, true) :: Model
end

local function carriedModelIn(character: Model): Model?
	for _, d in ipairs(character:GetChildren()) do
		if d:IsA("Model") and CollectionService:HasTag(d, GameConfig.Tags.CarriedPod) then
			return d
		end
	end
	return nil
end

local ok, err = pcall(function()
	check(map ~= nil, "the map folder exists (loose pods are parented to it)")
	if not map then
		return
	end

	--== 1. HOLDING A PLANT, TAKING A POD ======================================
	local b1 = body("HoldsPlant")
	local p1, pack1 = stand("HoldsPlant", -401, b1)
	CarryService.WatchBody(p1, b1)
	local plant = tool("Nubkin", "nubkin")
	plant.Parent = b1
	check(CarryService.TryTake(p1, loosePod()), "a player holding a plant can take a pod")
	check(CarryService.IsCarrying(p1), "and is carrying it")
	check(plant.Parent == pack1, "the held plant went back to the Backpack")
	check(carriedModelIn(b1) ~= nil, "the raid pod is the one thing in both arms")
	local plantsInHands = 0
	for _, d in ipairs(b1:GetChildren()) do
		if d:IsA("Tool") and d:GetAttribute("SpeciesId") then
			plantsInHands += 1
		end
	end
	check(plantsInHands == 0, "no plant Tool is left in the hands")

	--== 2. EQUIPPING A PLANT WHILE CARRYING ===================================
	local second = tool("Petalpip", "petalpip")
	second.Parent = pack1
	second.Parent = b1
	task.wait(0.15)
	check(second.Parent == pack1, "a plant equipped onto a carry is put back a frame later")
	check(carriedModelIn(b1) ~= nil and CarryService.IsCarrying(p1), "and the pod is still carried")

	--== 3. A BAT IS NOT A PLANT ===============================================
	local bat = tool("Rootwood Bat", nil)
	bat.Parent = b1
	task.wait(0.15)
	check(bat.Parent == b1, "a bat in hand is left alone while carrying")
	bat.Parent = pack1

	--== 4. ONCE THE CARRY ENDS, PLANTS MAY BE HELD AGAIN ======================
	check(CarryService.Drop(p1, ORIGIN), "the pod is dropped")
	second.Parent = b1
	task.wait(0.15)
	check(second.Parent == b1, "with empty arms, an equipped plant stays equipped")

	--== 5. TWO PLANTS AND A BAT IN HAND, THEN A TAKE ==========================
	local b2 = body("FullHands")
	local p2, pack2 = stand("FullHands", -402, b2)
	CarryService.WatchBody(p2, b2)
	local a = tool("Nubkin", "nubkin")
	local c = tool("Crookreed", "crookreed")
	local bat2 = tool("Comet Bat", nil)
	a.Parent = b2
	c.Parent = b2
	bat2.Parent = b2
	check(CarryService.TryTake(p2, loosePod()), "a player with full hands can still take a pod")
	check(a.Parent == pack2 and c.Parent == pack2, "every plant was put away")
	check(bat2.Parent == b2, "the bat was not")

	--== 6. NOTHING TO PUT AWAY, OR NOWHERE TO PUT IT ==========================
	local b3 = body("NoBackpack")
	local p3: any = { Name = "NoBackpack", UserId = -403, Parent = Players, Character = b3 }
	function p3.FindFirstChildOfClass(): any
		return nil
	end
	local lonely = tool("Nubkin", "nubkin")
	lonely.Parent = b3
	local okMove, moved = pcall(CarryService.PutPlantsAway, p3)
	check(okMove and moved == 0 and lonely.Parent == b3, "no Backpack: nothing moves and nothing throws")
	check(CarryService.PutPlantsAway(p2) == 0, "empty hands: nothing to move")
end)

fixture:Destroy()
if map then
	for _, d in ipairs(map:GetChildren()) do
		if not before[d] and d:GetAttribute("SpeciesId") ~= nil then
			d:Destroy()
		end
	end
end

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return ("CarryHandsSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails, table.concat(fails, "\n  "))
end
return ("CarryHandsSpec: %d passed, 0 failed"):format(pass)
