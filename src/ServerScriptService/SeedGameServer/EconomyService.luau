--!strict
-- Steal a Seed :: EconomyService
--
-- THE FAUCET. Rule 6: cash mints here and nowhere else.
--
--==============================================================================
-- WHY THAT RULE IS WORTH THE INCONVENIENCE
--
-- PlayerDataService.AddCash is the MECHANISM -- it clamps and marks dirty. It
-- does not decide what earns. If five services each paid out "just this one
-- case", the answer to "why does this player have eight million" would live in
-- five files, and balancing the game would mean reading all of them.
--
-- One file. Anything that wants to pay a player asks this service to do it.
--
-- It said "one loop, one call" until the stall started buying bags. There are
-- TWO ways to earn now -- the payout loop below, and SellHeld -- and they are
-- both in this file for exactly the reason the rule exists: "why does this
-- player have eight million" still has one file to read, and the two answers
-- sit forty lines apart. Adding a third belongs here too.
--
--==============================================================================
-- WHAT EARNS: GROWN PLANTS, AND ONLY GROWN ONES
--
-- Straight off SeedData.IncomePerSecond, which is the size tier scaled by the
-- species' rarity and by how deep the biome it came from is. This file does not
-- know those factors and must not learn them: one calculation, in SeedData,
-- shared with every readout that shows the player a number.
--
-- A pod in the ground pays nothing and a sprout pays nothing -- the wait IS the
-- cost, and paying during it would turn planting into a deposit rather than a
-- bet.
--
-- That also makes the plot readable as a balance sheet: what you can SEE
-- standing up is what is paying you.
--
--==============================================================================
-- PAID FOR TIME ACTUALLY ELAPSED, NOT PER TICK
--
-- rate * dt, where dt is measured rather than assumed to be TICK. A server that
-- hitches for three seconds still owes three seconds of income, and a loop that
-- pays a flat amount per iteration quietly underpays exactly when the server is
-- struggling.
--
-- The clock starts when the player is first seen paying, not when they joined,
-- so nobody is paid for time before their plants existed.
--
--==============================================================================
-- NO OFFLINE PAYOUT THIS PASS, DELIBERATELY
--
-- Growth uses an absolute os.time() and keeps running while you are away; CASH
-- does not. Those are different promises and this one is deferred on purpose --
-- an offline faucet needs a claim flow, a cap, and an anti-abuse story, and
-- none of that belongs in the pass that first makes the number move.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlantService = require(script.Parent:WaitForChild("PlantService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))

local EconomyService = {}
-- After PlantService (50): this reads what PlantService is growing.
EconomyService.Priority = 55

local TICK = 1

-- player -> os.clock() when they were last paid.
local lastPaid: { [Player]: number } = {}
-- player -> cash minted this session, for Snapshot. Diagnostics only; the
-- profile is the truth.
local minted: { [Player]: number } = {}

local running = false
local serviceConnections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/EconomyService] " .. message)
end

--==============================================================================
-- WHAT ONE PLAYER IS OWED PER SECOND
--
-- Public because the HUD will want to show it, and because a rate anybody can
-- ask for is a rate nobody has to re-derive.
--==============================================================================
function EconomyService.RateFor(player: Player): number
	local plot = PlotService.PlotOf(player)
	if not plot then
		return 0
	end
	-- Belt and braces on "only the plot's owner". PlotOf already answers that,
	-- but the two are separate tables and a lease that changed hands between
	-- them is exactly the sort of thing that pays the wrong person.
	if PlotService.OwnerOf(plot) ~= player then
		return 0
	end
	local rate = 0
	-- The INSTANCE tier, not the species sheet -- a faucet that ignored the roll
	-- would pay every Nubkin the same whatever came out of the pod. The SPECIES
	-- goes with it because rarity and biome are the other two factors, and
	-- GrownIn has always returned both.
	--
	-- Rounded per PLANT, inside IncomePerSecond, and summed after: a bed of
	-- twelve pays the sum of twelve whole numbers, which is what the garden
	-- panel adds up and shows.
	for _, grown in ipairs(PlantService.GrownIn(plot)) do
		rate += SeedData.IncomePerSecond(grown.species, grown.tier)
	end
	return rate
end

--==============================================================================
-- THE TICK
--==============================================================================
local function payEveryone()
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		-- Only while they are in the server. GetPlayers is that check; there is
		-- no queue of absent players to pay.
		if PlayerDataService.IsReady(player) then
			local since = lastPaid[player]
			lastPaid[player] = now
			if since then
				local dt = now - since
				-- A player who has just arrived, or whose clock was reset,
				-- gets no lump sum.
				if dt > 0 and dt < 30 then
					local rate = EconomyService.RateFor(player)
					if rate > 0 then
						local amount = rate * dt
						-- THE ONLY POSITIVE AddCash IN THE GAME.
						if PlayerDataService.AddCash(player, amount) then
							minted[player] = (minted[player] or 0) + amount
						end
					end
				end
			end
		else
			-- Not ready yet: do not start their clock, or the seconds spent
			-- loading a profile become seconds of income the moment it lands.
			lastPaid[player] = nil
		end
	end
end

local function forget(player: Player)
	lastPaid[player] = nil
	minted[player] = nil
end

--==============================================================================
-- LIFECYCLE
--==============================================================================

--==============================================================================
-- THE STALL BUYS THE BAG
--
-- The second way to earn, and the only one that is not a rate: a one-off for
-- everything the player is holding. Priced by SeedData.SellPrice, which is
-- thirty seconds of what the same plant would pay standing in the ground -- see
-- the banner there for why selling is deliberately the worse deal.
--
-- WHAT IS SOLD, AND WHAT IS NOT
--
-- Tools, in the Backpack and in the player's hands, because equipping MOVES a
-- Tool between the two and a sell that missed the one they were holding would
-- be the most obvious possible bug.
--
-- NOT the pod welded to them by a raid. That one has not been banked yet -- it
-- is still loot being carried home, CarryService owns it, and selling it out of
-- their arms at the stall would be taking something they had not put down.
--
-- COUNTED AND PAID ONCE. The tools are destroyed first and the total paid
-- after, so a failure between the two cannot pay twice; AddCash clamps, and a
-- refusal there leaves the bag already gone, which is why the amount is
-- computed from what was actually removed rather than from what was found.
--
-- The save follows for free: CarryService watches both containers for
-- ChildRemoved and re-snapshots the hotbar at the end of the frame.
--==============================================================================
function EconomyService.SellHeld(player: Player): (number, number)
	if player.Parent ~= Players then
		return 0, 0
	end

	local sold, total = 0, 0
	local function take(container: Instance?)
		if not container then
			return
		end
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") then
				local id = tool:GetAttribute("SpeciesId")
				local tier = tonumber(tool:GetAttribute(GameConfig.Attributes.CarryingKg))
				-- The species was already being looked up to validate the tool;
				-- it is now also what prices it, so a Mythic out of Starbloom
				-- sells for what it was worth standing up.
				local species = if type(id) == "string" then SeedData.Get(id) else nil
				if species and tier and tier >= 1 then
					total += SeedData.SellPrice(species, tier)
					sold += 1
					tool:Destroy()
				end
			end
		end
	end
	take(player:FindFirstChildOfClass("Backpack"))
	take(player.Character)
	CarryService.SyncHeldNow(player)

	if sold == 0 then
		return 0, 0
	end
	if total > 0 then
		PlayerDataService.AddCash(player, total)
	end
	log(string.format("%s sold %d item(s) at the stall for %s.",
		player.Name, sold, GameConfig.compact(total)))
	return sold, total
end

function EconomyService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(lastPaid)
	table.clear(minted)
end

function EconomyService.Start()
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(forget))

	running = true
	task.spawn(function()
		while running do
			task.wait(TICK)
			-- pcall so one bad profile cannot stop the faucet for everybody.
			local ok, err = pcall(payEveryone)
			if not ok then
				warn("[Seed/EconomyService] pay tick failed: " .. tostring(err))
			end
		end
	end)

	log(string.format(
		"Ready. The only faucet: grown plants pay their size tier scaled by species "
		.. "rarity (%.2f-%.2fx) and biome depth (%.2f-%.2fx), ticking every %ds.",
		SeedData.RarityMultiplier.Common, SeedData.RarityMultiplier.Divine,
		SeedData.BiomeMultiplier.greenhollow, SeedData.BiomeMultiplier.starbloom, TICK))
end

--==============================================================================
-- DIAGNOSTICS
--==============================================================================
function EconomyService.Snapshot(): string
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.Get(player)
		table.insert(rows, string.format("%s: %.0f/sec, %.0f cash (%.0f minted this session)",
			player.Name, EconomyService.RateFor(player),
			profile and profile.Cash or 0, minted[player] or 0))
	end
	table.sort(rows)
	return if #rows > 0 then table.concat(rows, " | ") else "nobody earning"
end

return EconomyService
