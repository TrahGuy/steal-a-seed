--!strict
-- Steal a Seed :: BonusChestService
--
-- The free Bonus Chest in the safe hub (2026-09-27 launch pass). Everything the
-- chest promises is in GameConfig.BonusChest; this file keeps those promises.
--
--==============================================================================
-- A CLAIM IS NOT REAL UNTIL IT IS SAVED
--
-- The whole claim, in order, with nothing a client sends in it -- the chest's
-- ProximityPrompt is the request, and Triggered carries no arguments:
--
--   1. refuse anything not allowed: the chest off, no profile, a profile that
--      cannot be saved at all, the guide unfinished, the cooldown still
--      running, or another claim for this player already in flight;
--   2. roll one reward, server-side;
--   3. write the cooldown, the reward and its expiry to the profile, together;
--   4. SAVE, and wait for the answer;
--   5. only if the save landed: publish it and say so. If it did not, put back
--      exactly the three values that were there and say THAT instead.
--
-- While 3-5 are in flight the claim is invisible: the faucets read
-- Multiplier, which answers 1 for a player mid-claim, and nothing is
-- published. So a boost is never paid, shown or confirmed ahead of the save
-- that makes it real.
--
-- A LOST ANSWER DOES NOT GRANT TWICE. The result lives on the profile and in
-- the attributes, not in the reply. If the reply never reaches the client, the
-- attributes do, and the chest UI draws from those; a second press finds the
-- cooldown running and is refused. If the DataStore committed but its answer
-- was lost, step 5 treats it as a failure, puts the old values back, and the
-- next save writes those over the orphan -- the player was told nothing was
-- granted and nothing is.
--
-- ONE AT A TIME PER PLAYER. `claiming` is set before the first yield and
-- cleared after the last, so a second prompt fired in the same frame -- or a
-- forged one -- is refused as BUSY rather than rolling again.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local TutorialData = require(Shared:WaitForChild("TutorialData"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local Metrics = require(script.Parent:WaitForChild("Metrics"))

local CHEST = GameConfig.BonusChest
local ATTR = CHEST.Attributes

local BonusChestService = {}
-- After PlayerDataService (20), whose profiles it reads, and the map (1).
BonusChestService.Priority = 58

local claiming: { [Player]: boolean } = {}
local serviceConnections: { RBXScriptConnection } = {}
local channel: RemoteEvent? = nil
local running = false
local rng = Random.new()

local function log(message: string)
	print("[Seed/BonusChestService] " .. message)
end

--==============================================================================
-- THE ROLL
--
-- A table field rather than a local so a test can hold it to one answer and
-- see both outcomes on purpose. Weighted, and the weights are equal today --
-- the 50/50 the chest shows.
--==============================================================================
function BonusChestService.RollReward(): string
	local total = 0
	for _, reward in ipairs(CHEST.Rewards) do
		total += reward.Weight
	end
	local pick = rng:NextNumber() * total
	for _, reward in ipairs(CHEST.Rewards) do
		pick -= reward.Weight
		if pick < 0 then
			return reward.Id
		end
	end
	return CHEST.Rewards[#CHEST.Rewards].Id
end

--==============================================================================
-- WHAT THE FAUCETS ASK
--
-- EconomyService.RateFor asks for "income", TreadmillService's payout asks for
-- "training", and nothing else asks at all -- which is what keeps a reward out
-- of sales, cash packs, offline claims, purchases and admin grants. 1 unless
-- a SAVED boost of that kind is running right now (GameConfig.
-- bonusChestMultiplier), and 1 while a claim is still waiting on its save.
--==============================================================================
function BonusChestService.Multiplier(player: Player, kind: string): number
	if claiming[player] then
		return 1
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return 1
	end
	return GameConfig.bonusChestMultiplier(profile.ChestBoost, profile.ChestBoostEndsAt, os.time(), kind)
end

--==============================================================================
-- THE ATTRIBUTES THE CHEST UI DRAWS FROM
--
-- Written only on a change, from the tick and after every claim, so a boost
-- expiring is an attribute going nil in the same second the faucets stop
-- paying it, and a finished guide unlocks the chest within a second. Skipped
-- while a claim is in flight: a pending claim is not something to show.
--==============================================================================
local function put(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

local function publish(player: Player)
	if claiming[player] or player.Parent ~= Players then
		return
	end
	local profile = PlayerDataService.Get(player)
	if not profile or not CHEST.Enabled then
		put(player, ATTR.Unlocked, nil)
		put(player, ATTR.NextAt, nil)
		put(player, ATTR.Boost, nil)
		put(player, ATTR.EndsAt, nil)
		return
	end
	put(player, ATTR.Unlocked, if TutorialData.IsComplete(profile.Tutorial) then true else nil)
	put(player, ATTR.NextAt, profile.ChestNextAt)
	local active = GameConfig.bonusChestMultiplier(profile.ChestBoost, profile.ChestBoostEndsAt,
		os.time(), profile.ChestBoost) > 1
	put(player, ATTR.Boost, if active then profile.ChestBoost else nil)
	put(player, ATTR.EndsAt, if active then profile.ChestBoostEndsAt else nil)
end

--==============================================================================
-- THE CLAIM
--
-- Returns ok, a reason code, and the reward Id on success. The codes are what
-- the chest UI turns into words: OK, DISABLED, NOT_READY, NOT_SAVED (a
-- temporary profile, which could never keep a reward), LOCKED (the guide),
-- COOLDOWN, BUSY and SAVE_FAILED.
--==============================================================================
--==============================================================================
-- A BOOST FROM ELSEWHERE: THE REWARD WHEEL (2026-09-27)
--
-- The same boost, through the same one slot, by the same rule a claim follows:
-- it REPLACES whatever is running, for BoostSeconds from now. The cooldown is
-- left exactly as it was, so winning a boost on the wheel neither opens nor
-- delays the chest. Refused while a chest claim is saving for this player --
-- that claim's rollback would otherwise put the old boost back over this one --
-- and the wheel keeps the prize owed and delivers it a moment later.
--
-- The caller saves: the wheel recorded the prize before it got here.
--==============================================================================
function BonusChestService.GrantBoost(player: Player, boostId: string): boolean
	if claiming[player] or player.Parent ~= Players or GameConfig.bonusChestReward(boostId) == nil then
		return false
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return false
	end
	if not PlayerDataService.SetChest(player, profile.ChestNextAt, boostId, os.time() + CHEST.BoostSeconds) then
		return false
	end
	publish(player)
	log(string.format("%s won a %s boost on the wheel, for %ds.", player.Name, boostId, CHEST.BoostSeconds))
	return true
end

function BonusChestService.Claim(player: Player): (boolean, string, string?)
	if not CHEST.Enabled then
		return false, "DISABLED", nil
	end
	if player.Parent ~= Players then
		return false, "GONE", nil
	end
	if claiming[player] then
		return false, "BUSY", nil
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return false, "NOT_READY", nil
	end
	if not PlayerDataService.IsPersistent(player) then
		return false, "NOT_SAVED", nil
	end
	if not TutorialData.IsComplete(profile.Tutorial) then
		return false, "LOCKED", nil
	end
	local now = os.time()
	if now < profile.ChestNextAt then
		return false, "COOLDOWN", nil
	end

	claiming[player] = true
	local wasNext, wasBoost, wasEnds = profile.ChestNextAt, profile.ChestBoost, profile.ChestBoostEndsAt
	local reward = BonusChestService.RollReward()
	-- A claim REPLACES: the expiry is set, never extended.
	PlayerDataService.SetChest(player, now + CHEST.CooldownSeconds, reward, now + CHEST.BoostSeconds)
	-- Through the module table, not a captured local, so a test can stand in a
	-- save that fails -- the one path that cannot be reached any other way.
	local called, saved = pcall(PlayerDataService.Save, player)
	if not (called and saved == true) then
		PlayerDataService.SetChest(player, wasNext, wasBoost, wasEnds)
		claiming[player] = nil
		publish(player)
		warn(string.format("[Seed/BonusChestService] %s's claim did not save (%s); nothing was granted.",
			player.Name, if called then "save refused" else tostring(saved)))
		return false, "SAVE_FAILED", nil
	end
	claiming[player] = nil
	publish(player)
	log(string.format("%s claimed the Bonus Chest: %s for %ds, next claim in %ds.", player.Name, reward,
		CHEST.BoostSeconds, CHEST.CooldownSeconds))
	-- Launch analytics: a CONFIRMED grant only -- the save above succeeded.
	Metrics.chestClaimed(player, reward)
	return true, "OK", reward
end

local function answer(player: Player, ok: boolean, reason: string, reward: string?)
	local remote = channel
	if not remote or player.Parent ~= Players then
		return
	end
	local profile = PlayerDataService.Get(player)
	pcall(function()
		remote:FireClient(player, CHEST.ReplyAction, {
			ok = ok,
			reason = reason,
			reward = reward,
			nextAt = if profile then profile.ChestNextAt else nil,
			endsAt = if profile and ok then profile.ChestBoostEndsAt else nil,
		})
	end)
end

--==============================================================================
-- THE CHEST ITSELF
--
-- Primitive parts in the hub's own blocky plastic -- no purchased or uploaded
-- asset. Built into its own folder, not the map's, because MapService destroys
-- and rebuilds SeedMap and must not be able to take the chest with it.
-- PERSISTENT under streaming, so a player across the field still has the
-- chest (and its sign) and never meets a prompt that has not streamed in.
--==============================================================================
local WOOD = Color3.fromRGB(150, 98, 58)
local WOOD_DARK = Color3.fromRGB(116, 74, 42)
local GOLD = Color3.fromRGB(240, 196, 72)
local PLINTH = Color3.fromRGB(128, 132, 124)

local function part(model: Model, name: string, size: Vector3, cf: CFrame, colour: Color3,
	material: Enum.Material): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function build(): Model?
	local old = Workspace:FindFirstChild(CHEST.FolderName)
	if old then
		old:Destroy()
	end
	if not CHEST.Enabled then
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = CHEST.FolderName
	folder.Archivable = false

	local model = Instance.new("Model")
	model.Name = "BonusChest"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local origin = CFrame.new(CHEST.Position) * CFrame.Angles(0, math.rad(CHEST.FacingDegrees), 0)
	-- -Z is the chest's front: the side with the lock, the side its prompt and
	-- sign face.
	local plinth = part(model, "Plinth", Vector3.new(5.6, 0.5, 4.4), origin * CFrame.new(0, 0.25, 0),
		PLINTH, Enum.Material.Slate)
	local body = part(model, "Body", Vector3.new(4, 2.2, 2.8), origin * CFrame.new(0, 1.6, 0),
		WOOD, Enum.Material.WoodPlanks)
	part(model, "Lid", Vector3.new(4.2, 1.0, 3.0), origin * CFrame.new(0, 3.2, 0), WOOD_DARK,
		Enum.Material.WoodPlanks)
	for _, x in ipairs({ -1.35, 1.35 }) do
		part(model, "Band", Vector3.new(0.35, 3.35, 3.1), origin * CFrame.new(x, 2.18, 0), GOLD,
			Enum.Material.Metal)
	end
	local lock = part(model, "Lock", Vector3.new(0.8, 0.9, 0.3), origin * CFrame.new(0, 2.7, -1.55), GOLD,
		Enum.Material.Metal)
	model.PrimaryPart = plinth
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") then
			d.CanCollide = true
			d.CanTouch = false
		end
	end
	lock.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimPrompt"
	-- Custom, so PromptUI draws it in the same chrome as every other prompt.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Open"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	-- Held a moment, like every prompt that gives something: walking past with
	-- E down is not a decision.
	prompt.HoldDuration = CHEST.PromptHoldSeconds
	prompt.MaxActivationDistance = CHEST.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	table.insert(serviceConnections, prompt.Triggered:Connect(function(player: Player)
		local ok, reason, reward = BonusChestService.Claim(player)
		answer(player, ok, reason, reward)
	end))

	model.Parent = folder
	folder.Parent = Workspace
	return model
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function BonusChestService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(claiming)
	channel = nil
end

function BonusChestService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	channel = if found and found:IsA("RemoteEvent") then found else nil
	if not channel then
		warn("[Seed/BonusChestService] No GameEvent remote; claims will not be answered.")
	end

	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		claiming[player] = nil
	end))

	local model = build()
	running = true
	task.spawn(function()
		while running do
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(publish, player)
			end
			task.wait(1)
		end
	end)

	if model then
		local at = model:GetPivot().Position
		log(string.format("Ready. The chest stands at (%.0f, %.0f, %.0f); a claim every %ds after the guide, "
			.. "%d reward(s) for %ds each.", at.X, at.Y, at.Z, CHEST.CooldownSeconds, #CHEST.Rewards,
			CHEST.BoostSeconds))
	else
		log("Ready. The Bonus Chest is SWITCHED OFF (GameConfig.BonusChest.Enabled = false).")
	end
end

-- The attributes, on demand: a claim harness or a spec reads the same numbers
-- the tick would publish a second later.
BonusChestService.Publish = publish

return BonusChestService
